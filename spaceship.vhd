------------------------------------------------------------------------------------------
-- Space Invaders - Contrôleur du Vaisseau Spatial
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spaceship is
    port(
        clk: in std_logic;                              -- Horloge 50 MHz
        not_reset: in std_logic;                        -- Reset Asynchrone
        px_x: in std_logic_vector(9 downto 0);          -- Coordonnée X du Pixel Courant
        px_y: in std_logic_vector(9 downto 0);          -- Coordonnée Y du Pixel Courant
        nes_left: in std_logic;                         -- Bouton LEFT de la Manette
        nes_right: in std_logic;                        -- Bouton RIGHT de la Manette
        spaceship_x: out std_logic_vector(9 downto 0);  -- Coordonnée X du Vaisseau Spatial
        spaceship_y: out std_logic_vector(9 downto 0);  -- Coordonnée X du Vaisseau Spatial
        rgb_pixel: out std_logic_vector(0 to 2)         -- Couleur de l'Objet du Pixel Courant
    );
end spaceship;


architecture behaviour of spaceship is
    
    -- Dimensions de l'Ecran
    constant SCREEN_W: integer := 640;
    constant SCREEN_H: integer := 480;

    -- how far down the spaceship will be
    constant OFFSET: integer := 416;
    -- size of the spaceship frame (32x32)
    constant SIZE: integer := 32;

    -- address is made of row and column adresses
    -- addr <= (row_address & col_address);
    signal addr: std_logic_vector(9 downto 0);
    signal row_address, col_address: std_logic_vector(4 downto 0);

    -- Drapeau Pixe Courant dans la Zone d'Affichage du Vaisseau Spatial
    signal output_enable: std_logic;

    -- Couleur RGB du Puxel Courant du Vaisseau Spatial
    signal spaceship_rgb: std_logic_vector(2 downto 0);

    -- x-coordinate of the spaceship
    signal position, position_next: std_logic_vector(9 downto 0);

begin
 
------------------------------------------------
-- Gestion de la Position du Vaisseau Spatial   
------------------------------------------------ 
    
    process(clk, not_reset)
    begin
        -- Reset Asynchrone --> Position Initiale du Vaisseau Spatial
        if not_reset = '0' then
            position <= conv_std_logic_vector(304, 10);
        -- Sinon, Déplacement en Fonction des COnsignes de la Manette 
        --      et Arret si On Atteint le Bord de l'Ecran
        elsif rising_edge(clk) then
            if (nes_right = '1' and position + SIZE < SCREEN_W) then
                position <= position + 1; 
            elsif (nes_left = '1' and position > 0) then
                position <= position - 1;
            end if;        
        end if;
    end process;

   
    -- Génération des Coordonnées du Vaisseau sur les Ports de Sortie
        -- +13 gives the center coordinate 
        -- this is used in missile.vhd
    spaceship_x <= position + 13;
    spaceship_y <= conv_std_logic_vector(OFFSET, 10);


------------------------------------------------
-- Gestion de l'Affichage du Vaisseau Spatial   
------------------------------------------------ 

    -- Drapeau Indiquant que les Pixel Courant Est dans la Zone du Vaisseau Spatial
    output_enable <= '1' when (px_x >= position and
                               px_x < position + SIZE and
                               px_y >= OFFSET and
                               px_y < OFFSET + SIZE) else
                     '0';

    -- Couleur de ce Pixel Courant (Lu Depuis
    rgb_pixel <= spaceship_rgb when output_enable = '1' else
                 (others => '0');


    -- Calcul de l'Adresse du Vaisseau Spatial pour Adresser la Table
    row_address <= px_y(4 downto 0) - OFFSET;
    col_address <= px_x(4 downto 0) - position(4 downto 0);
    addr <= row_address & col_address;

    -- Instanciation de la Table du Visuel du Vaisseau Spatial
    spaceship_rom:
        entity work.spaceship_rom(content)
        port map(addr => addr, data => spaceship_rgb);

end behaviour;

