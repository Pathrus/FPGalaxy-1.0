------------------------------------------------------------------------------------------
-- Space Invaders - Trame du Vaisseau Spatial
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity spaceship_rom is
    port(
        addr: in std_logic_vector(9 downto 0);  -- Adresse du Pixel de l'Alien � Afficher
        data: out std_logic_vector(2 downto 0)  -- Couleur RGB de ce Pixel
    );
end spaceship_rom;

architecture content of spaceship_rom is
    type rgb_array is array(0 to 31) of std_logic_vector(2 downto 0);
    type rom_type is array(0 to 31) of rgb_array;

    signal rgb_row: rgb_array;

    -- Tableau RGB de l'Alien
    constant SPACESHIP: rom_type :=
    (
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "000", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "111", "000", "000", "000", "111", "111", "000", "000", "000", "000", "000", "111", "000", "111", "000", "000", "000", "000", "000", "111", "111", "000", "000", "000", "111", "000", "000", "000", "000"),
        ("000", "000", "111", "111", "111", "000", "111", "111", "000", "000", "000", "000", "000", "111", "000", "000", "000", "111", "000", "000", "000", "000", "000", "111", "111", "000", "111", "111", "111", "000", "000", "000"),
        ("000", "111", "111", "000", "111", "111", "111", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "111", "111", "111", "000", "111", "111", "000", "000"),
        ("000", "111", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "111", "000", "111", "000", "111", "000", "111", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "111", "000", "000"),
        ("000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000"),
        ("000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000"),
        ("000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000"),
        ("000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000"),
        ("000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000"),
        ("000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000", "000", "111", "000", "111", "000", "000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000"),
        ("000", "111", "000", "000", "000", "000", "000", "000", "000", "111", "111", "111", "000", "000", "000", "000", "000", "000", "000", "111", "111", "111", "000", "000", "000", "000", "000", "000", "000", "111", "000", "000"),
        ("000", "111", "111", "000", "000", "000", "000", "000", "111", "111", "000", "111", "111", "000", "000", "000", "000", "000", "111", "111", "000", "111", "111", "000", "000", "000", "000", "000", "111", "111", "000", "000"),
        ("000", "000", "111", "111", "000", "000", "000", "111", "111", "000", "000", "000", "111", "111", "000", "000", "000", "111", "111", "000", "000", "000", "111", "111", "000", "000", "000", "111", "111", "000", "000", "000"),
        ("000", "000", "000", "111", "111", "000", "111", "111", "000", "000", "000", "000", "000", "111", "111", "111", "111", "111", "000", "000", "000", "000", "000", "111", "111", "000", "111", "111", "000", "000", "000", "000"),
        ("000", "000", "000", "111", "000", "111", "000", "111", "000", "000", "000", "000", "000", "000", "111", "111", "111", "000", "000", "000", "000", "000", "000", "111", "000", "111", "000", "111", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"),
        ("000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000")
    );
begin
    -- Lecture d'une Case du Tableau
    rgb_row <= SPACESHIP(conv_integer(addr(9 downto 5)));
    data <= rgb_row(conv_integer(addr(4 downto 0)));
end content;
