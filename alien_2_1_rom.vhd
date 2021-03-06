------------------------------------------------------------------------------------------
-- Space Invaders - Trame 1 de l'Alien Type 2 (Affich� sur la 2�me Ligne)
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alien21_rom is
    port(
        addr: in std_logic_vector(9 downto 0);  -- Adresse du Pixel de l'Alien � Afficher
        data: out std_logic_vector(2 downto 0)  -- Couleur RGB de ce Pixel
    );
end alien21_rom;

architecture content of alien21_rom is
    type rgb_array is array(0 to 31) of std_logic_vector(2 downto 0);
    type rom_type is array(0 to 31) of rgb_array;

    signal rgb_row: rgb_array;

    -- Tableau RGB de l'Alien
    constant ALIEN: rom_type :=
    (
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "111", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "111", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "111", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "111", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "111", "111", "100", "100", "111", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "111", "111", "100", "100", "111", "111", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "111", "100", "100", "111", "000", "111", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "111", "111", "000", "111", "100", "100", "111", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "111", "100", "100", "111", "000", "000", "111", "111", "100", "100", "100", "100", "100", "100", "100", "100", "111", "111", "000", "000", "111", "100", "100", "111", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "111", "100", "100", "111", "000", "000", "000", "111", "111", "100", "100", "100", "100", "100", "100", "111", "111", "000", "000", "000", "111", "100", "100", "111", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "111", "100", "100", "100", "111", "000", "000", "000", "111", "100", "100", "100", "100", "100", "100", "111", "000", "000", "000", "111", "100", "100", "100", "111", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "111", "111", "100", "100", "100", "111", "111", "111", "100", "100", "100", "100", "100", "100", "100", "100", "111", "111", "111", "100", "100", "100", "111", "111", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "111", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "111", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "111", "100", "100", "100", "100", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "100", "100", "100", "100", "111", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "100", "100", "100", "111", "111", "000", "111", "000", "111", "000", "111", "000", "111", "000", "111", "000", "111", "100", "100", "111", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "100", "100", "100", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "100", "111", "111", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "100", "100", "111", "000", "111", "000", "111", "000", "111", "000", "111", "000", "111", "000", "111", "111", "111", "111", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100", "100", "100", "100", "100", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000")
    );
begin
    -- Lecture d'une Case du Tableau
    rgb_row <= ALIEN(conv_integer(addr(9 downto 5)));
    data <= rgb_row(conv_integer(addr(4 downto 0)));
end content;
