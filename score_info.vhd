------------------------------------------------------------------------------------------
-- Space Invaders - Gestion de l'Affichage du Score
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity score_info is
    port(
        clk: in std_logic;                          -- Horloge 50 MHz
        not_reset: in std_logic;                    -- Reset Asynchrone
        px_x: in std_logic_vector(9 downto 0);      -- Coordonnée X du Pixel Courant
        px_y: in std_logic_vector(9 downto 0);      -- Coordonnée Y du Pixel Courant
        score: in std_logic_vector(15 downto 0);    -- Score de la Partie
        rgb_pixel: out std_logic_vector(0 to 2) -- Couleur d'AFfichage du Niveau
    );
end score_info;

architecture display of score_info is
    
    -- Taille et Positionnement en Y du Texte du SCORE
    constant WIDTH: integer := 48;
    constant HEIGHT: integer := 8;
    constant Y_OFFSET: integer := 8;

    -- Accès à la Table ASCII
    signal font_addr: std_logic_vector(8 downto 0);
    signal font_data: std_logic_vector(0 to 7);
    signal font_pixel: std_logic;

    -- Gestion des Lettres LEVEL
    signal text_font_addr: std_logic_vector(8 downto 0);
    -- Gestion de la Valeur Numérique de LEVEL
    signal number_font_addr: std_logic_vector(8 downto 0);

    -- Autorisation d'Afficher le Texte ou les Nombres
    signal text_enable: std_logic;
    signal number_enable: std_logic;

    -- Digits BCD du LEVEL
    signal bcd: std_logic_vector(3 downto 0);
    signal bcd0, bcd1, bcd2, bcd3, bcd4: std_logic_vector(3 downto 0);

begin

    -- Conversion Bin --> BCD de la Valeur Numérique du LEVEL
    bin_to_bcd:
        entity work.bin2bcd(behaviour)
        generic map(N_BIN => 16)
        port map(
            clk => clk, not_reset => not_reset,
            binary_in => score,
            bcd0 => bcd0, bcd1 => bcd1, bcd2 => bcd2,
            bcd3 => bcd3, bcd4 => bcd4
        );

    -- Digit BCD à Afficher (Selon la Position du Pixel COurant)
    bcd <= bcd0 when px_x(9 downto 3) = 10 else
           bcd1 when px_x(9 downto 3) = 9 else
           bcd2 when px_x(9 downto 3) = 8 else
           bcd3 when px_x(9 downto 3) = 7 else
           bcd4 when px_x(9 downto 3) = 6 else
           (others => '0');


    -- Affichage du Texte LEVEL quand le Pixel Courant Est dans la Bonne Zone d'Affichage
    --  Le Level Est Affiché en Haut à Gauche de l'Ecran, en Dessous du LEVEL
    text_enable <= '1' when (px_x >= 0 and
                             px_x < WIDTH and
                             px_y >= Y_OFFSET and
                             px_y < Y_OFFSET + HEIGHT) else
                   '0';

    -- Affichage de la Valeur du LEVEL quand le Pixel Courant Est dans la Bonne Zone d'Affichage
    -- +40 used to right-align the score with level
    number_enable <= '1' when (px_x >= WIDTH and
                               px_x < WIDTH + 40 and
                               px_y >= Y_OFFSET and
                               px_y < Y_OFFSET + HEIGHT) else
                     '0';

    -- Adresses des Différentes Lettres Selon la Position du Pixel Courant
    with px_x(9 downto 3) select
        text_font_addr <= "110011000" when "0000000", -- S
                          "100011000" when "0000001", -- C
                          "101111000" when "0000010", -- O
                          "110010000" when "0000011", -- R
                          "100101000" when "0000100", -- E
                          "000000000" when others;    -- space


    -- Adresse des Chiffres du LEVEL dans la Table ASCII
    --      numbers start at memory location 128
    --      '1' starts at 136, '2' at 144 and so on
    --      bcd is multiplied by 8 to get the right digit
    number_font_addr <= conv_std_logic_vector(128, 9) + (bcd & "000");

    -- Calcul de l'Adresse à Envoyer à la Table ASCII
    font_addr <= px_y(2 downto 0) + text_font_addr when text_enable = '1' else
                 px_y(2 downto 0) + number_font_addr when number_enable = '1' else
                 (others => '0');

    -- Lecture de la Table ASCII
    codepage:
        entity work.codepage_rom(content)
        port map(addr => font_addr, data => font_data);

    -- Affichage de la Couleur du Pixel Renvoyé par la Table
    font_pixel <= font_data(conv_integer(px_x(2 downto 0)));
    rgb_pixel <= "111" when font_pixel = '1' else "000";

end display;

