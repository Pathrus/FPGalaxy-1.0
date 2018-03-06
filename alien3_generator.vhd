------------------------------------------------------------------------------------------
-- Space Invaders - Contrôleur de la 1ère Ligne d'Aliens (Aliens Type 3)
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alien3 is
    port(
        clk: in std_logic;                                      -- Horloge 50 Mhz
        not_reset: in std_logic;                                -- Reset Asynchrone
        px_x: in std_logic_vector(9 downto 0);                  -- Coordonnée X du Pixel Courant
        px_y: in std_logic_vector(9 downto 0);                  -- Coordonnée Y du Pixel Courant
        alien_group_coord_x: in std_logic_vector(9 downto 0);   -- Coordonnée X du Groupe d'Aliens
        alien_group_coord_y: in std_logic_vector(9 downto 0);   -- Coordonnée Y du Groupe d'Aliens
        missile_coord_x: in std_logic_vector(9 downto 0);       -- Coordonnée X du Missile
        missile_coord_y: in std_logic_vector(9 downto 0);       -- Coordonnée Y du Missile
        restart: in std_logic;                                  -- Drapeau Restart
        destroyed: out std_logic;                               -- Drapeau Alien Détruit
        defeated: out std_logic;                                -- Drapeau Ligne d'Aliens Détruite
        explosion_x: out std_logic_vector(9 downto 0);          -- Coordonnée X de l'Explosion
        explosion_y: out std_logic_vector(9 downto 0);          -- Coordonnée Y de l'Explosion
        rgb_pixel: out std_logic_vector(2 downto 0)                 -- Couleur de l'Objet du Pixel Courant             
    );
end alien3;

architecture generator of alien3 is
   
   -- Etats pour la Condition des Aliens
    type states is (act, wait_clk);
    signal EP, EF: states;


    -- Dimension d'un Alien (8 * 32)
    constant ALIEN_WIDTH: integer := 256;
    constant ALIEN_HEIGHT: integer := 32;
    -- 3rd level aliens are at the bottom (64px below master coord)
    constant OFFSET: integer := 0;

    -- Délai Entre les Deux Visuels des Aliens (Frame 1 / Frame 2)
    constant FRAME_DELAY: integer := 10000000;

    -- Pour Afficher la Couleur de l'Alien s'il Est Encore Vivant
    signal output_enable: std_logic;

    -- address is made of row and column adresses
    -- addr <= (row_address & col_address);
    signal addr: std_logic_vector(9 downto 0);
    signal row_address, col_address: std_logic_vector(4 downto 0);

    signal relative_x: std_logic_vector(9 downto 0);

    -- Position du Missile dans la Ligne d'Aliens
    signal missile_relative_x: std_logic_vector(9 downto 0);
    signal attacked_alien: std_logic_vector(2 downto 0);

    -- Position du Missile dans le Visuel de l'Alien
    signal position_in_frame: std_logic_vector(4 downto 0);

    -- whether missile is in alien zone
    signal missile_arrived: std_logic;

    signal destruction: std_logic;

    -- condition of aliens: left (0) to right (7)
    -- second level aliens need three hits to get killed
    signal alive: std_logic_vector(0 to 7);
    signal injured1,injured2: std_logic_vector(0 to 7);
    signal alien_alive: std_logic;

    -- Numéro de Trame du Visuel des Aliens et COmpteur de Durée d'Affichage
    signal frame: std_logic;
    signal frame_counter: std_logic_vector(26 downto 0);

    signal alien_rgb, alien31_rgb, alien32_rgb: std_logic_vector(2 downto 0);
    -- which alien is currently being drawn
    -- leftmost = 0, rightmost = 7
    signal alien_number: std_logic_vector(2 downto 0);

begin

-----------------------------------------------
--  Gestion de l'Interaction Missile / Aliens
-----------------------------------------------

    -- Drapeau Indiquant Si le Missile Atteint la Ligne des Alines
    missile_arrived <= '1' when missile_coord_y < alien_group_coord_y + OFFSET + ALIEN_HEIGHT and
                                missile_coord_x > alien_group_coord_x and
                                missile_coord_x < alien_group_coord_x + ALIEN_WIDTH else
                       '0';

    -- Position du Missile dans la Ligne d'Aliens
    --      Permet de Savoir Quel Alien dans la Ligne A Eté Touché
    missile_relative_x  <=  (missile_coord_x - alien_group_coord_x) when missile_arrived = '1' 
                            else (others => '0');

    -- Coordonnée (de 0 à 7) du Missile dans la Ligne (Mis à Jour En Cas de Cible Atteinte)
    attacked_alien      <=  missile_relative_x(7 downto 5) when missile_arrived = '1' 
                            else (others => '0');
    
    -- Position du Missile dans le Visuel de l'Alien
    position_in_frame   <=  missile_relative_x(4 downto 0) when missile_arrived = '1' 
                            else (others => '0');



    -- Mise à Jour Registre Etat de la Machine à Etats
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            EP <= act;
        elsif rising_edge(clk) then
            EP <= EF;
        end if;
   end process;

   -- Evolution de la Machine à Etats
    process(missile_arrived, attacked_alien,position_in_frame,EP)
    begin
        case EP is
            -- Etat ACT --> Passage en WAIT_CLK Si un Missile Touche les Aliens
            when act        =>  EF <= act;
                                if missile_arrived = '1' and
                                    alive(conv_integer(attacked_alien)) = '1' and
                                        position_in_frame > 0 and
                                            position_in_frame < 29 then
                    
                                   EF<= wait_clk;
                                end if;
                                
            -- Etat WAIT_CLK --> Retour en ACT
            when wait_clk   =>  EF <= act;
        end case;
     end process;

    -- Mise à Jour Etat des Aliens
    process(clk, not_reset)
    begin
        -- A l'Initialisation: Tous Vivants, Aucun Blessé
        if not_reset = '0' then
            alive <= (others => '1');
            injured1 <= (others => '0');
            injured2 <= (others => '0');
        elsif rising_edge(clk) then
            
            -- Par Défaut, pas de Destruction
            destruction <= '0';
            
            -- Dans l'état ACT
            if EP = act then
                -- Si Redémarrage Partie, Valeurs Initiales
                if restart = '1' then
                    alive <= (others => '1');
                    injured1 <= (others => '0');
                    injured2 <= (others => '0');
                -- Sinon , si un Missile Arrive
                elsif missile_arrived = '1' and
                    alive(conv_integer(attacked_alien)) = '1' and
                        position_in_frame > 0 and
                            position_in_frame < 29 then

                                -- Si Alien Pas Blessé --> Etat = Blessé 1          
                                if injured2(conv_integer(attacked_alien)) = '0' then
                                    if injured1(conv_integer(attacked_alien)) = '0' then
                                        injured1(conv_integer(attacked_alien)) <= '1';
                                    destruction <= '1';
                                    -- Si Alien Blessé 1 --> Etat = Blessé 2          
                                    else
                                        injured2(conv_integer(attacked_alien)) <= '1';
                                    destruction <= '1';
                                    end if;
                                -- Si Alien Blessé 2 --> Etat = Détruit          
                                else
                                    alive(conv_integer(attacked_alien)) <= '0';
                                    destruction <= '1';
                                end if;
                end if;
            end if;
        end if;
   end process;

    -- Port de Sortie Destroyed
    destroyed <= destruction;

    -- Coordonnée de l'Explosion Recalculée à Partir des Infos Précédentes
    explosion_x <= alien_group_coord_x + (attacked_alien & "00000");
    explosion_y <= alien_group_coord_y + OFFSET;

    -- Drapeau Indiquant que Tous les Aliens de la Ligne Sont Détruits
    defeated <= '1' when alive = 0 else '0';
    -- attacked alien number is multiplied by 32

-----------------------------------------
--  Gestion de l'Affichage des Aliens
-----------------------------------------

    -- Génération Drapeau Alien_Alive pour SAvoir si un Alien de la Ligne Est Vivant ou Non
    relative_x <= px_x - alien_group_coord_x;
    alien_number <= relative_x(7 downto 5);
    alien_alive <= alive(conv_integer(alien_number));

    -- Autorisation d'Afficher un Alien Si
    --      Il Est Vivant et Si On Est Dans Sa Zone d'Affichage
    output_enable <= '1' when (alien_alive = '1' and 
                               px_x >= alien_group_coord_x and
                               px_x < alien_group_coord_x + ALIEN_WIDTH and
                               px_y >= alien_group_coord_y + OFFSET and
                               px_y < alien_group_coord_y + OFFSET + ALIEN_HEIGHT) 
                           
                     else '0';

    -- Gestion de la Durée d'Affichage des Visuels des Aliens (Frame 1 / 2)
    process(clk, not_reset)
    begin
        -- Reset Asynchrone
        if not_reset = '0' then
            frame <= '0';
            frame_counter <= (others => '0');
        -- Front Horloge
        elsif rising_edge(clk) then
            
            -- Gestion du Compteur de Durée d'Affichage
            if (frame_counter < FRAME_DELAY) then
                frame_counter <= frame_counter + 1;
            else
                frame_counter <= (others => '0');
            end if;
            
            -- Mise à Jour Numéro de Trame des Aliens
            if frame_counter = 0 then 
                frame <= not frame; 
            end if;
        end if;
    end process;

    -- Sélection Couleur RGB en Fonction de la Trame
    alien_rgb <= alien31_rgb when frame = '0' else
                 alien32_rgb;

    -- Couleur à Afficher sur l'Ecran VGA
    rgb_pixel <= alien_rgb when output_enable = '1' else
                 (others => '0');



    -- Coordonnées du Pixel de l'Alien à Afficher
    row_address <= px_y(4 downto 0) - alien_group_coord_y(4 downto 0);
    col_address <= px_x(4 downto 0) - alien_group_coord_x(4 downto 0);
    addr <= row_address & col_address;

    -- Instanciations des 2 Trames des Aliens
    alien_31:
        entity work.alien31_rom(content)
        port map(addr => addr, data => alien31_rgb);

    alien_32:
        entity work.alien32_rom(content)
        port map(addr => addr, data => alien32_rgb);

end generator;
