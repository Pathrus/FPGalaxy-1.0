------------------------------------------------------------------------------------------
-- Space Invaders - Top Level
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity main is
    port(
        clk_100MHz, not_reset: in std_logic;        -- Horloge 100 MHz, Reset Asynchrone
        hsync, vsync: out std_logic;                -- Synchro Horizontale/Verticale VGA
        rgb: out std_logic_vector(2 downto 0);      -- Signal RGB VGA
        buzzer: out std_logic;                      -- Sortie Son
        nes_data: in std_logic;                     -- Signaux Manette NES
        nes_clk_out: out std_logic;
        nes_ps_control: out std_logic
    );
end main;

architecture behavior of main is
    
    -- Horloge 05 et 25 MHz
    signal clk_50MHz,clk_25MHz: std_logic;
    signal cpt: std_logic_vector(1 downto 0);
    -- Signazux VGA
    signal rgb_reg, rgb_next: std_logic_vector(2 downto 0); -- Tampons RGB
    signal video_on: std_logic;                             -- Zone Image Active
    signal px_x, px_y: std_logic_vector(9 downto 0);        -- Coordonnées Pixel

    -- Signazux Jeux
    signal shot, destroyed: std_logic;

    -- Signazux Mannette NES
    signal nes_a, nes_b,
           nes_select, nes_start,
           nes_up, nes_down,
           nes_left, nes_right: std_logic;

    -- Signazux Son
    signal buzzer1, buzzer2: std_logic;

begin

    -- Génération Horloge 50 et 25 MHz (Division par 2 et 4)
    process(clk_100MHz,not_reset)
    begin
        -- Reset Asynchrone
        if not_reset='0' then clk_50MHz <= '0'; cpt <= "00";
        -- Front Horloge 100 MHz
        elsif rising_edge(clk_100MHz) then 
            clk_50MHz<=not clk_50MHz; 
            cpt <= cpt+1;
        end if;
    end process;

    clk_25MHz <= cpt(1);

    -- Mise à Jour du Signal RGB en Fonction de la Consigne du Jeu
    process(clk_50MHz,not_reset)
    begin
        -- Reset Asynchrone
        if not_reset='0' then rgb <= "000";
        -- Front Horloge 50 MHz
        elsif rising_edge(clk_50MHz) then
            rgb <= rgb_next;
        end if;
    end process;

--    rgb <= rgb_reg; -- Mise à Jour Port de Sortie


    -- Instanciation Contrôleur VGA
    vga:
        entity work.vga(archi)
        port map(
		    clk25 => clk_25MHz,   -- Horloge 25 MHz
		    reset => not_reset,	  -- Reset Asynchrone
            hsync => hsync,       -- Synchro Horizontale
            vsync => vsync,       -- Synchro Verticale
            visible => video_on,  -- Partie Visible de l'Image
            endframe => open,     -- Dernier Pixel Visible d'une Trame
            xpos => px_x,         -- Coordonnee X du Pixel Courant
            ypos => px_y          -- Coordonnee Y du Pixel Courant
        );

    -- Instanciation Contrôleur Graphique du Jeu
    graphics:
        entity work.graphics(dispatcher)
        port map(
            clk => clk_50MHz,                   -- Horloge 50 MHz
            not_reset => not_reset,             -- Reset Asynchrone
            px_x => px_x,                       -- Coordonnée X du Pixel Courant
            px_y => px_y,                       -- Coordonnée Y du Pixel Courant
            video_on => video_on,               -- Zone Visible de l'Image
            nes_a => nes_a,                     -- Bouton A Manette NES
            nes_b => nes_b,                     -- Bouton B Manette NES
            nes_left => nes_left,               -- Bouton LEFT Manette NES
            nes_right => nes_right,             -- Bouton RIGHT Manette NES
            rgb_stream => rgb_next,             -- Couleur du Pixel à Afficher
            shooting_sound => shot,             -- Son Tir
            destruction_sound => destroyed      -- Son Explosion
        );


    -- Signal Sonore en Sortie
    buzzer <= buzzer1 or buzzer2;

    -- Instanciation des Contrôleurs de Son
    sound1:
        entity work.player(behaviour)
        port map(
            clk => clk_50MHz, not_reset => not_reset,
            shooting_sound => shot, explosion_sound => '0',
            buzzer => buzzer1
        );
    sound2:
        entity work.player(behaviour)
        port map(
            clk => clk_50MHz, not_reset => not_reset,
            shooting_sound => '0', explosion_sound => destroyed,
            buzzer => buzzer2
        );

    NES_controller:
        entity work.controller(arch)
        port map(
            clk => clk_50MHz, not_reset => not_reset,
            data_in => nes_data,
            clk_out => nes_clk_out,
            ps_control => nes_ps_control,
            gamepad(0) => nes_a,      gamepad(1) => nes_b,
            gamepad(2) => nes_select, gamepad(3) => nes_start,
            gamepad(4) => nes_up,     gamepad(5) => nes_down,
            gamepad(6) => nes_left,   gamepad(7) => nes_right
        );


end behavior;

