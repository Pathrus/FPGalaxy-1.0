------------------------------------------------------------------------------------------
-- Space Invaders - Contrôleur des Explosions
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity explosion is
    port(
        clk: in std_logic;                          -- Horloge 50 MHz
        not_reset: in std_logic;                    -- Reset Asynchrone
        px_x: in std_logic_vector(9 downto 0);      -- Coordonnée X du Pixel Courant
        px_y: in std_logic_vector(9 downto 0);      -- Coordonnée Y du Pixel Courant
        destruction: in std_logic;                  -- Drapeau Collision Missile <--> Alien
        explosion_x: std_logic_vector(9 downto 0);  -- Coordonnée X de l'Explosion
        explosion_y: std_logic_vector(9 downto 0);  -- Coordonnée Y de l'Explosion
        rgb_pixel: out std_logic_vector(2 downto 0) -- Couleur du Pixel Courant de l'Explosion
    );
end explosion;

architecture behaviour of explosion is

    -- frame size (32x32 px)
    constant SIZE: integer := 32;

    -- colour masks
    constant RED: std_logic_vector := "100";
    constant YELLOW: std_logic_vector := "110";

    -- for delay of 100ms
    constant DELAY: integer := 2000000;
    signal counter: std_logic_vector(20 downto 0);

    -- Etats de la MAE pour les Différentes Phases de l'Explosion
    type states is (idle, state1, state2, state3);
    signal EP, EF: states;

    -- Drapeau d'Affichage de l'Explodion si Pixel Courant dans Sa Zone de l'Ecran
    signal output_enable: std_logic;

    -- address is made of row and column adresses
    -- addr <= (row_address & col_address);
    signal addr: std_logic_vector(9 downto 0);
    signal row_address, col_address: std_logic_vector(4 downto 0);

    -- COuleur de l'Explosion
    signal explosion_rgb, explosion_mask: std_logic_vector(2 downto 0);

begin

------------------------------
-- Gestion de l'Explosion
------------------------------

    -- Registre d'Etat de la MAE
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            EP <= idle;
        elsif rising_edge(clk) then
            EP <= EF;
        end if;
    end process;

    -- Evolution des Etats de la MAE
    --  On Sort de IDLE Si Collision Missile <--> Alien
    --  Ensuite On Change d'Etat A Chauqe Fin du Cycle du Compteur
    animation: process(EP, counter, destruction)
    begin
        case EP is
            -- ETAT IDLE
            when idle   =>  EF <= idle;
                            if destruction = '1' then
                                EF <= state1;
                            end if;
            
            -- ETAT STATE1
            when state1 =>  EF <= state1;
                            if counter = DELAY - 1 then
                                EF <= state2;
                            end if;
            
            -- ETAT STATE2
            when state2 =>  EF <= state2;
                            if counter = DELAY - 1 then
                                EF <= state3;
                            end if;
            
            -- ETAT STATE3
            when state3 =>  EF <= state3;
                            if counter = DELAY - 1 then
                                EF <= idle;
                            end if;
        end case;
    end process;

    -- Gestion du Compteur de Durée de Chaque Etat de l'Explosion
    --      Compteur à l'Arrêt en IDLE
    --      Incrémentation jusqu'à DELAY dans les Autres Etats
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk) then
            
            -- Etat IDLE
            if (EP = idle) then 
                counter <= (others => '0');

            -- Autres Etats
            elsif (EP = state1) or (EP = state2) or (EP = state3) then 
                if counter = DELAY - 1 then
                    counter <= (others => '0');
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;


------------------------------
-- Affichage de l'Explosion
------------------------------

    -- Condition d'Affichage de l'Explosion
    --      Il Faut que le Pixel Courant Soit dans la Zone de l'Explosion
    --      et que l'on Soit dans un Etat Autre que IDLE
    output_enable <= '1' when (EP /= idle and 
                               px_x >= explosion_x and
                               px_x < explosion_x + SIZE and
                               px_y >= explosion_y and
                               px_y < explosion_y + SIZE) else
                     '0';

    -- Couleur del'Explosion
    explosion_mask <= explosion_rgb when EP = state1 and
                                         -- only allow reg through
                                         explosion_rgb(1) = '0' else
                      explosion_rgb when EP = state2 and
                                         -- allow red and yellow through
                                         explosion_rgb(0) = '0' else
                                         -- allow all colours through
                      explosion_rgb when EP = state3 else
                      (others => '0');

    
    -- Couleur du Pixel Courant de l'Explosion
    rgb_pixel <= explosion_mask when output_enable = '1' else (others => '0');

    -- Adressage de la Table du Visuel de l'Explosion
    row_address <= px_y(4 downto 0) - explosion_y(4 downto 0);
    col_address <= px_x(4 downto 0) - explosion_x(4 downto 0);
    addr <= row_address & col_address;

    -- Table Visuel de l'Explosion
    explosion:
        entity work.explosion_rom(content)
        port map(addr => addr, data => explosion_rgb);

end behaviour;