------------------------------------------------------------------------------------------
-- Space Invaders - Convertisseur Bonaire BCD pour l'Affichage du Score et du Level
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bin2bcd is
    generic(N_BIN: positive := 16); -- Nombre de Bits du Mot Binaire
    port(
        clk: in std_logic;                                              -- Horloge 50 MHz
        not_reset: in std_logic;                                        -- Reset Asynchrone
        binary_in: in std_logic_vector(N_BIN - 1 downto 0);             -- Mot Binaire d'Entrée
        bcd0, bcd1, bcd2, bcd3, bcd4: out std_logic_vector(3 downto 0)  -- Digits BCD en Sortie
    );
end bin2bcd;

architecture behaviour of bin2bcd is
    
    -- Etats de la MAE du Convertisseur
    type states is (start, shift, done);
    signal EP,EF: states;

    signal binary: std_logic_vector(N_BIN - 1 downto 0);
    signal bcds, bcds_reg: std_logic_vector(19 downto 0);
    -- output register keep output constant during conversion
    signal bcds_out_reg: std_logic_vector(19 downto 0);
    -- need to keep track of shifts
    signal shift_counter: natural range 0 to N_BIN;
begin


    -- Registre d'Etat de la MAE
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            EP <= start;
        elsif rising_edge(clk) then
            EP <= EF;
        end if;
    end process;

    -- Evolution de la MAE
    convert:
    process(EP, shift_counter)
    begin
    
        case EP is
            when start =>   EF <= shift;
            when shift =>   EF <= shift;
                            if shift_counter = N_BIN then
                                EF <= done;
                            end if;
            when done =>    EF <= start;
        end case;
    end process;

    -- Conversion BIN --> BCD
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            binary <= (others => '0');
            bcds <= (others => '0');
            bcds_out_reg <= (others => '0');
            shift_counter <= 0;
        elsif rising_edge(clk) then

            case EP is
                when start  =>  binary <= binary_in;
                                bcds <= (others => '0');
                                shift_counter <= 0;
                
                when shift  =>  if shift_counter /= N_BIN then
                                    binary <= binary(N_BIN - 2 downto 0) & 'L';
                                    bcds <= bcds_reg(18 downto 0) & binary(N_BIN - 1);
                                    shift_counter <= shift_counter + 1;
                                end if;
            
                when done   =>  bcds_out_reg <= bcds;
            end case;
        end if;
    end process;


    bcds_reg(19 downto 16)  <=  bcds(19 downto 16) + 3  when bcds(19 downto 16) > 4 else
                                bcds(19 downto 16);
    bcds_reg(15 downto 12)  <=  bcds(15 downto 12) + 3  when bcds(15 downto 12) > 4 else
                                bcds(15 downto 12);
    bcds_reg(11 downto 8)   <=  bcds(11 downto 8) + 3   when bcds(11 downto 8) > 4 else
                                bcds(11 downto 8);
    bcds_reg(7 downto 4)    <=  bcds(7 downto 4) + 3    when bcds(7 downto 4) > 4 else
                                bcds(7 downto 4);
    bcds_reg(3 downto 0)    <=  bcds(3 downto 0) + 3    when bcds(3 downto 0) > 4 else
                                bcds(3 downto 0);


    -- Envoi des Digits BCD sur les Ports de Sortie
    bcd4 <= bcds_out_reg(19 downto 16);
    bcd3 <= bcds_out_reg(15 downto 12);
    bcd2 <= bcds_out_reg(11 downto 8);
    bcd1 <= bcds_out_reg(7 downto 4);
    bcd0 <= bcds_out_reg(3 downto 0);

end behaviour;