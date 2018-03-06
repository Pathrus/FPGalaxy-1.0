------------------------------------------------------------------------------------------
-- Space Invaders - Géénrateur du Signal Sonore
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sounds is
    port(
        clk: in std_logic;                          -- Horloge 50 MHz
        not_reset: in std_logic;                    -- Reset Asynchrone
        enable: in std_logic;                       -- Activation du Son
        period: in std_logic_vector(18 downto 0);   -- Période du Signal Sonore
        volume: in std_logic_vector(2 downto 0);    -- Volume du Signal Sonore
        buzzer: out std_logic                       -- Signal Sonore Généré
    );
end sounds;

architecture generator of sounds is
    -- Compteur de Temps
    signal counter: std_logic_vector(18 downto 0);
    -- Durée du Niveau Haut du Signal Sonore
    signal pulse_width: std_logic_vector(18 downto 0);
begin

    -- Compteur de Temps
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            counter <= (others => '0');
        elsif clk'event and clk = '0' then
            if counter = period then
                counter <= (others => '0');
            else 
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- duty cycle:
    --    max:   50% (18 downto 1)
    --    min: 0.78% (18 downto 7)
    --    off when given 0 (18 downto 0)!
--    pulse_width <= period(18 downto conv_integer(volume));
    pulse_width <= period(18 downto 0);

    -- Génération du Signal Sonore
    buzzer <= '1' when (enable = '1' and counter < pulse_width) else '0';

end generator;