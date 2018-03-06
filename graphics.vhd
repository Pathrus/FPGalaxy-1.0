------------------------------------------------------------------------------------------
-- Space Invaders - Contrôleur Graphique des Objets du Jeu
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity graphics is
    port(
        clk: in std_logic;                              -- Horloge 50 MHz
        not_reset: in std_logic;                        -- Reset Asynchrone
        px_x: in std_logic_vector(9 downto 0);          -- Coordonnée X du Pixel Courant
        px_y: in std_logic_vector(9 downto 0);          -- Coordonnée Y du Pixel Courant
        video_on: in std_logic;                         -- Zone Visible de l'Image
        nes_a: in std_logic;                            -- Bouton A Manette NES
        nes_b: in std_logic;                            -- Bouton B Manette NES
        nes_left: in std_logic;                         -- Bouton LEFT Mannette NES
        nes_right: in std_logic;                        -- Bouton RIGHT Manette NES
        rgb_stream: out std_logic_vector(2 downto 0);   -- Couleur du Puxel à Afficher
        shooting_sound: out std_logic;                  -- Son Tir
        destruction_sound: out std_logic                -- Son Explosion
    );
end graphics;

architecture dispatcher of graphics is
    constant ALIENS_WIDTH: integer := 256;       -- Largeur du Groupe d'Aliens
    constant DELAY: integer := 25000000;         -- Pour Compter 0,5 seconde

    -- MAE Sens de Déplacmeent Horizondal des Aliens
    type states is (left, right);
    signal EP_H, EF_H: states;   -- Ettat Présent, Etat Futur
        
    -- MAE Sens de Déplacmeent Vertical des Aliens
    type states_v is (up, down);
    signal EP_V, EF_V: states_v; -- Ettat Présent, Etat Futur

    -- Compteur Pour le Déplacement des Aliens
    signal counter: std_logic_vector(24 downto 0);

    -- Coordonnées de Référence du Groupe d'Aliens (xmin/ymin)
    signal alien_group_coord_x, alien_group_coord_y: std_logic_vector(9 downto 0);

    -- Coordonnées du Missile
    signal missile_coord_x, missile_coord_y: std_logic_vector(9 downto 0);

    -- Coordonnées du Vaisseau Spatial
    signal spaceship_x, spaceship_y: std_logic_vector(9 downto 0);

    -- Coordonnées de l'Explosion
    signal explosion_x: std_logic_vector(9 downto 0);
    signal explosion_y: std_logic_vector(9 downto 0);

    -- Coordonnées des Aliens
    signal alien1_x, alien1_y,
           alien2_x, alien2_y,
           alien3_x, alien3_y: std_logic_vector(9 downto 0);

    -- Couleurs des Objets
    signal alien1_rgb, alien2_rgb, alien3_rgb: std_logic_vector(2 downto 0);
    signal spaceship_rgb: std_logic_vector(2 downto 0);
    signal missile_rgb: std_logic_vector(2 downto 0);
    signal explosion_rgb: std_logic_vector(2 downto 0);
    signal level_rgb, score_rgb: std_logic_vector(2 downto 0);

    --Drapeaux Explosion ou Destruction d'Aliens
    signal destruction: std_logic;
    signal destroyed1, destroyed2, destroyed3: std_logic;
    signal defeated1, defeated2, defeated3: std_logic;

    -- for starting a new level
    signal restart: std_logic;

    -- Niveau et Score
    signal level: std_logic_vector(8 downto 0);
    signal score: std_logic_vector(15 downto 0);

begin

-----------------------------------------------------
-- Machines à Ztats pour le Déplacement des Aliens
--      1 MAE pour le Déplacement Horizontal
--      1 MAE pour le Déplacement Vertical
-----------------------------------------------------
    -- Registres d'Etats
    process(clk, not_reset)
    begin
        -- Reset Asynchrone - Etats d'Initialisation
        if not_reset = '0' then
            EP_H <= right;
            EP_V <= up;
        -- Mise à Jour Etat Présent
        elsif rising_edge(clk) then
            EP_H <= EF_H;
            EP_V <= EF_V;
        end if;
    end process;


    -- Evolution des Etats de la MAE
    process(EP_H, EP_V, alien_group_coord_x,counter)
    begin

        -- Par Défaut, pas de Changement d'Etat
        EF_H <= EP_H;
        EF_V <= EP_V;
        
        -- Evolution du Sens de Déplacement Vertical
        --      Le Changement de Direction Se Fait à la Fin du Délai Mesuré par le Compteur
        --      Changement du Sens Vertical: Automatique
        --      Changement du Sens Horizontal: Si le Groupe d'Aliens Arrive au Bord de l'Ecran
        if counter = 0 then
        
            -- Etat Futur du Déplacement Vertical
            case EP_V is
                when up     =>  EF_V <= down;
                when down   =>  EF_V <= up;
            end case;

            -- Etat Futur du Déplacement Horizontal
            case EP_H is
                when right  =>  if alien_group_coord_x + ALIENS_WIDTH = 640 then
                                    EF_H <= left;
                                end if;
                when left   =>  if alien_group_coord_x = 0 then
                                    EF_H <= right;
                                end if;
            end case;
        end if;
    end process;


    
-----------------------------------------------------
-- Compteur du Délai pour le Mouvement des Aliens
-----------------------------------------------------
    process(clk,not_reset)
    
    begin
    
        -- Reset Asynchrone
        if not_reset='0' then             
            counter <= (others => '0');
        -- Front d'Horloge
        elsif rising_edge(clk) then 
            if counter < DELAY then
                counter <= counter + 1;
            else
                counter <= (others => '0');
            end if;
        end if;
    end process;


---------------------------------------
-- Gestion du Déplacement des Aliens
---------------------------------------
    process(clk,not_reset)
    
    begin
        -- Reset Asynchrone - Position par Défaut du Groupe d'Aliens
        if not_reset='0' then             
            alien_group_coord_x <= conv_std_logic_vector(192, 10);
            alien_group_coord_y <= conv_std_logic_vector(34, 10);
        -- Front d'Horloge
        elsif rising_edge(clk) then 
        
            -- Le Déplacement des Aliens S'Effectue à la Fin du DELAI mesuré par le Compteur
            --      On Met à Jour les Cooronnées X et Y du Groupe d'Aliens
            if counter = 0 then
                
                -- Déplacmeent Vertical - En Fonction de l'Etat PRésent EP_V
                case EP_V is
                    when up     =>  alien_group_coord_y <= alien_group_coord_y - 4;
                    when down   =>  alien_group_coord_y <= alien_group_coord_y + 4;
                end case;

                -- Déplacmeent Horizontal - En Fonction de l'Etat PRésent EP_H
                --      Les Tests Permettent de ne pas Sortir d' l'Ecran
                case EP_H is
                    when right =>   if alien_group_coord_x + ALIENS_WIDTH < 640 then
                                        alien_group_coord_x <= alien_group_coord_x + 16;
                                    else 
                                        alien_group_coord_x <= conv_std_logic_vector(384, 10); 
                                        -- 384 = 640 - ALIENS_WIDTH
                                    end if;
                    when left =>    if alien_group_coord_x > 0 then
                                        alien_group_coord_x <= alien_group_coord_x - 16;
                                    else 
                                        alien_group_coord_x <= (others => '0');
                                    end if;
                end case;
            end if;
        end if;
    end process;


---------------------------------------
-- Gestion des Coordonnées des Explosions
---------------------------------------
    
    process(clk,not_reset)
    
    begin
    
        -- Reset Asynchrone - Coordonnées par Défaut
        if not_reset='0' then             
            explosion_x <= (others => '0');
            explosion_y <= (others => '0');
        -- Front d'Horloge
        -- Les Coordonnées de l'Explosion Sont Celles de l'Alien Détruit
        elsif rising_edge(clk) then 
            
           -- Si Alien de Type 1 (3ème Ligne) Détruit 
            if destroyed1 = '1' then 
                explosion_x <= alien1_x;
                explosion_y <= alien1_y;
           -- Si Alien de Type 2 (2ème Ligne) Détruit 
            elsif destroyed2 = '1' then 
                explosion_x <= alien2_x;
                explosion_y <= alien2_y;
           -- Si Alien de Type 3 (1ère Ligne) Détruit 
            elsif destroyed3 = '1' then 
                explosion_x <= alien3_x;
                explosion_y <= alien3_y;
            end if;
        end if;
    end process;



---------------------------------------
-- Gestion du Score et des Niveaux
---------------------------------------

    -- Destruction si un Alien A Eté Détruit
    destruction <= destroyed1 or destroyed2 or destroyed3;
    destruction_sound <= destruction;

    process(clk,not_reset)
    
    begin
    
        -- Reset Asynchrone
        if not_reset='0' then             
            level <= (0 => '1', others => '0');
            score <= (others => '0');
            restart <= '0';
        -- Front d'Horloge
        elsif rising_edge(clk) then 
            
            -- Gsstion Restart
            if (defeated1 and  defeated2 and defeated3) = '1' then
                restart <= '1';
            else restart <= '0';
            end if;
    
            -- Gsstion Level
            if (counter(0) = '0') and (defeated1 and  defeated2 and defeated3) = '1' then
                level <= level+1;
            end if;

            -- Gsstion du Score
            --      +2 à Chaque Destruction d'Alien
            if destruction = '1' then 
                score <= score + 2;  
            end if;
        end if;
    end process;
    

    
------------------------------------------------------------------------
-- Affichage des Couleurs
--      Il Faut Etre dans la Zone Visible de l'Image
--      L'Objet Correspondant au Pixel Courant Envoie Sa Couleur
--          Sinion, par Défaut les Objets Envoient RGB <= "000"
--      La Sortie rgb_stream est un OU du flux RGB de Tous les Objets
------------------------------------------------------------------------
    process(video_on,
            alien1_rgb, alien2_rgb, alien3_rgb,
            spaceship_rgb,missile_rgb, explosion_rgb,
            level_rgb, score_rgb)
    begin
        if video_on = '1' then
            
            rgb_stream <= "000" or
                          alien1_rgb or alien2_rgb or alien3_rgb or
                          spaceship_rgb or missile_rgb or
                          explosion_rgb or level_rgb or score_rgb;
        else
            rgb_stream <= (others => '0');
        end if;
    end process;



---------------------------------------------------------
-- Instanciation des Contrôleurs des Différents Objets
---------------------------------------------------------

    -- 3ème Ligne d'Aliens (Aliens Type 1)
    alien1:
        entity work.alien(generator)
        port map(
            clk => clk,                                     -- 
            not_reset => not_reset,
            px_x => px_x, 
            px_y => px_y,
            alien_group_coord_x => alien_group_coord_x,
            alien_group_coord_y => alien_group_coord_y,
            missile_coord_x => missile_coord_x,
            missile_coord_y => missile_coord_y,
            restart => restart,
            destroyed => destroyed1,
            defeated => defeated1,
            explosion_x => alien1_x, 
            explosion_y => alien1_y,
            rgb_pixel => alien1_rgb
        );

    -- 2ème Ligne d'Aliens (Aliens Type 2)
    alien2:
        entity work.alien2(generator)
        port map(
            clk => clk, not_reset => not_reset,
            px_x => px_x, px_y => px_y,
            alien_group_coord_x => alien_group_coord_x,
            alien_group_coord_y => alien_group_coord_y,
            missile_coord_x => missile_coord_x,
            missile_coord_y => missile_coord_y,
            restart => restart,
            destroyed => destroyed2,
            defeated => defeated2,
            explosion_x => alien2_x, explosion_y => alien2_y,
            rgb_pixel => alien2_rgb
        );

    -- 1ère Ligne d'Aliens (Aliens Type 3)
    alien3:
        entity work.alien3(generator)
        port map(
            clk => clk, not_reset => not_reset,
            px_x => px_x, px_y => px_y,
            alien_group_coord_x => alien_group_coord_x,
            alien_group_coord_y => alien_group_coord_y,
            missile_coord_x => missile_coord_x,
            missile_coord_y => missile_coord_y,
            restart => restart,
            destroyed => destroyed3,
            defeated => defeated3,
            explosion_x => alien3_x, explosion_y => alien3_y,
            rgb_pixel => alien3_rgb
        );


    -- Vaisseau Spatial
    spaceship:
        entity work.spaceship(behaviour)
        port map(
            clk => clk, not_reset => not_reset,
            px_x => px_x, px_y => px_y,
            nes_left => nes_left, nes_right => nes_right,
            spaceship_x => spaceship_x,
            spaceship_y => spaceship_y,
            rgb_pixel => spaceship_rgb
        );

    -- Missile
    missile:
        entity work.missile(behaviour)
        port map(
            clk => clk, not_reset => not_reset,
            px_x => px_x, px_y => px_y,
            nes_a => nes_a, nes_b => nes_b,
            spaceship_x => spaceship_x,
            spaceship_y => spaceship_y,
            destruction => destruction,
            missile_coord_x => missile_coord_x,
            missile_coord_y => missile_coord_y,
            shooting => shooting_sound,
            rgb_pixel => missile_rgb
        );

    -- Explosions
    explosion:
        entity work.explosion(behaviour)
        port map(
            clk => clk, not_reset => not_reset,
            px_x => px_x, px_y => px_y,
            destruction => destruction,
            explosion_x => explosion_x, explosion_y => explosion_y,
            rgb_pixel => explosion_rgb
        );

    -- Niveau
    level_display:
        entity work.level_info(display)
        port map(
            clk => clk, not_reset => not_reset,
            px_x => px_x, px_y => px_y,
            level => level,
            rgb_pixel => level_rgb
        );

    -- Score
    score_display:
        entity work.score_info(display)
        port map(
            clk => clk, not_reset => not_reset,
            px_x => px_x, px_y => px_y,
            score => score,
            rgb_pixel => score_rgb
        );
end dispatcher;

