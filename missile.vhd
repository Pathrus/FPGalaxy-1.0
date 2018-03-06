------------------------------------------------------------------------------------------
-- Space Invaders - Contr�leur des Missiles
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity missile is
    port(
        clk: in std_logic;                                  -- Horloge 50 MHz
        not_reset: in std_logic;                            -- REset Asynchrone
        px_x: in std_logic_vector(9 downto 0);              -- Coordonn�e X du Pixel Courant
        px_y: in std_logic_vector(9 downto 0);              -- Coordonn�e Y du Pixel Courant
        nes_a: in std_logic;                                -- Bouton A de la Manntte
        nes_b: in std_logic;                                -- Bouton B de la Manette
        spaceship_x: in std_logic_vector(9 downto 0);       -- Coordonn�e X du Vaisseau Spatial
        spaceship_y: in std_logic_vector(9 downto 0);       -- Coordonn�e Y du Vaisseau Spatial
        destruction: in std_logic;                          -- Drapeau Inquant que le Missile A Touch� une Cible
        missile_coord_x: out std_logic_vector(9 downto 0);  -- Coordonn�e X du Missile
        missile_coord_y: out std_logic_vector(9 downto 0);  -- Coordonn�e Y du Missile
        shooting: out std_logic;                            -- Drapeau Indiquant un Tir de Missile
        rgb_pixel: out std_logic_vector(0 to 2)             -- Couleur du Missile
    );
end missile;

architecture behaviour of missile is
    
    -- Taille du Missile
    constant WIDTH: integer := 4;
    constant HEIGHT: integer := 4;
    
    -- Vitesse du Missile
    constant DELAY: integer := 50000; -- 1kHz

    -- Table du Visuel du Missile
    type rom_type is array(0 to HEIGHT - 1) of
         std_logic_vector(WIDTH - 1 downto 0);
    constant MISSILE: rom_type := ("0100", "1110", "1110", "1010");
    
    
    signal missile_ready: std_logic;    -- Missile Pr�t � Etre Tir�
    signal button_pressed: std_logic;   -- Bouton de Tir Press� par l'Utilisateur

    -- Compteur de Temporisation pour le D�aplcement en Y du Missile
    signal counter: std_logic_vector(16 downto 0);

    -- Coordonn�e en X,Y du Missile
    signal x_coordinate: std_logic_vector(9 downto 0);
    signal y_coordinate: std_logic_vector(9 downto 0);

    -- Pour Afficher la Couleur du Missile
    signal output_enable: std_logic;

    -- Signaux pour Acc�der � la Table de la Trame Visuelle du Missile
    signal row_address, col_address: std_logic_vector(1 downto 0);
    signal data: std_logic_vector(WIDTH - 1 downto 0);

begin

-----------------------------------------
-- Interpr�tation des Commandes du Jeu
-----------------------------------------
    
    -- D�tection Appui sur un Bouton
    button_pressed <= '1' when (nes_a = '1' or nes_b = '1') else '0';

    -- Drapeau Indiquant qu'on Peut Tirer un Nouveau Missile
    process(clk, not_reset)
    begin
        -- Missile Pr�t � Tirer � l'Initialisation
        if not_reset = '0' then
            missile_ready <= '1';
            shooting <= '0';
        elsif rising_edge(clk) then
            
            -- Par D�faut, pas de Tir
            shooting <= '0';
            
            -- Si On Peut Lancer un Missile 
            --  et que l'Utilisateur Appuie sur un Bouton
            --      On Verrouille le Missile --> Shooting passe � 1
            if (button_pressed = '1' and missile_ready = '1') then
                missile_ready <= '0';
                shooting <= '1';
            -- Si le Missile Tir� Atteint une Cible ou Sort de l'Ecran
            --  Alors On Peut Lancer un Nouveau Missile 
            elsif (destruction = '1' or y_coordinate < 10) then
                missile_ready <= '1';
            end if;
        end if;
    end process;

----------------------------------------
-- Calcul des Coordonn�es du Missile
----------------------------------------

    -- Gestion du Compteur pour la Mise � Jour de la Coordonn�e Y du Missile
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk) then
            if (counter < DELAY) then
                counter <= counter + 1;
            else counter <= (others => '0');
            end if;
        end if;
    end process;

    -- Mise � Jour des Coordonn�es X et Y du Missile
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            x_coordinate <= (others => '0');
            y_coordinate <= (others => '0');
        elsif rising_edge(clk) then
        
            -- Coordonn�e X
            --  Si On Tire un Missile, On Prend la Position en X du Vaisseau Spatial
            --      La Position Est MAintenue Tant que le Missile Existe
            --          Remise � Z�ro Quand le Missile a Disparu
            if (missile_ready = '1' and button_pressed = '1') then
                x_coordinate <= spaceship_x;
            elsif (missile_ready = '1') then
                x_coordinate <= (others => '0');
            end if;

            -- Coordonn�e Y
            --  Si On Tire un Missile, On Prend la Position en Y du Vaisseau Spatial
            --      Le Missile Tir� Se D�place Ensuite Verticalement 
            --          � la Cadence du Compteur
            if (missile_ready = '1') then
                y_coordinate <= spaceship_y;
            elsif (missile_ready = '0' and counter = 0) then
                y_coordinate <= y_coordinate - 1;
            end if;
        end if;
    end process;

    -- Mise � Jour des Ports de Sortie
    missile_coord_x <= x_coordinate;
    missile_coord_y <= y_coordinate;

-----------------------------------------
--  Gestion de l'Affichage du Missile
-----------------------------------------


    -- Autorisation d'Afficher le missile si le Pixel Courant Est dans Sa Zone d'Affichage
    output_enable <= '1' when (missile_ready = '0' and
                               px_x >= x_coordinate and 
                               px_x < x_coordinate + WIDTH and
                               px_y >= y_coordinate and
                               px_y < y_coordinate + HEIGHT) else
                     '0';

    
    -- Coordonn�es du Pixel du Missile � Afficher
    row_address <= px_y(1 downto 0) - y_coordinate(1 downto 0);
    col_address <= px_x(1 downto 0) - x_coordinate(1 downto 0);

    -- Acc�s � la Table
    data <= MISSILE(conv_integer(row_address));

    -- COuleur du Pixel Courant du Missile
    rgb_pixel <= "111" when (output_enable = '1' and
                             data(conv_integer(col_address)) = '1') else
                 "000";


end behaviour;