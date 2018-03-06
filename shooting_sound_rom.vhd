------------------------------------------------------------------------------------------
-- Space Invaders - Table Son du Tir de Missile
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity shooting_sound is
    generic(
        ADDR_WIDTH: integer := 5    -- Dimensionnement de la Table
    );
    port(
        addr: in std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Adresse de la Table
        data: out std_logic_vector(8 downto 0)              -- Donnée Lue
    );
end shooting_sound;

architecture content of shooting_sound is
    type tune is array(0 to 2 ** ADDR_WIDTH - 1)
        of std_logic_vector(8 downto 0);


    -- TABLE DES NOTES
        --      Bits 8-6: Tonalité
        --      Bits 5-3: Durée
        --      Bits 2-0: Volume
    constant TEST: tune :=
    (
        "100001001",
        "011001011",
        "001001010",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000",
        "000000000"
);
begin

    -- Lecture de la Table
    data <= TEST(conv_integer(addr));
end content;

