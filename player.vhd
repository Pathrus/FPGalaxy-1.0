------------------------------------------------------------------------------------------
-- Space Invaders - Contrôleur de Son 1
--      Code Original: Armandas https://github.com/armandas/FPGalaxy
--      Revision/Commentaires Additionnels: Julien Denoulet
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity player is
    port(
        clk: in std_logic;              -- Horloge 50 MHz
        not_reset: in std_logic;        -- Reset Asynchrone
        shooting_sound: in std_logic;   -- Commande Génération du Son de Tir de Missile
        explosion_sound: in std_logic;  -- Commande Génération du Son de l'Explosion
        buzzer: out std_logic           -- Singal Sonore
    );
end player;

architecture behaviour of player is
    
    -- Caarctéristiques du Signal Sonore Demandé
    signal pitch: std_logic_vector(18 downto 0);
    signal duration: std_logic_vector(25 downto 0);
    signal volume: std_logic_vector(2 downto 0);

    -- Autorisation Génération du Son
    signal enable: std_logic;

    -- Compteur Durée d'une Note
    signal d_counter: std_logic_vector(25 downto 0);

    -- Notes à Jouer, Adresse dans la Table, Drapeau Changement de Note
    signal note: std_logic_vector(8 downto 0);
    signal note_addr: std_logic_vector(4 downto 0);
    signal change_note: std_logic;

    -- data source for tunes
    signal source: std_logic;

    -- container for current data selected by multiplexer
    signal data: std_logic_vector(8 downto 0);
    -- data containers for use with ROMs. Add more as needed.
    signal data_1, data_2: std_logic_vector(8 downto 0);

    -- Etats de la MAE Pilotant la Génération du Son
    type state_type is (off, playing);
    signal EP, EF: state_type;

    -- Démarrage Génération du Son
    signal start: std_logic;

begin

    -- Demande de Génération du Son
    start <= '1' when (shooting_sound = '1' or explosion_sound = '1') else '0';


    -- Registre d'Etat de la MAE
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            EP <= off;
        elsif rising_edge(clk) then
            EP <= EF;
        end if;
    end process;

    -- Evolution de la MAE
    process(EP, start, enable, duration, d_counter, note_addr, change_note)
    begin

        enable <= '0';
        -- On Commence à Jouer sur la Commande de Start
        -- On Arrête lorsque la Durée PRévue Est Ecoulée
        case EP is

            -- Etat OFF
            when off        =>  EF <= off;
                                if start = '1' then
                                    EF <= playing;
                                end if;

            -- Etat PLAYING            
            when playing    =>  enable <= '1';
                                EF <= playing;
                                if duration = 0 then
                                    EF <= off;
                                end if;
        end case;
    end process;


    -- Gestion des Notes à Jouer
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            source <= '0';
            note_addr <= (others => '0');
            note <= (others => '0');
        elsif rising_edge(clk) then

            -- Signal Sonore à Géénrer
            if shooting_sound = '1' then 
                source <= '0';
            elsif explosion_sound ='1' then
                source <= '1';
            end if;

            -- Mise à Jour de l'Adresse de la Note à Jouer
            if EP = off then 
                note_addr <= (others => '0');
            elsif EP = playing then
                if (duration > 0 and change_note = '1') then
                    note_addr <= note_addr+1;
                end if;
            end if;
            
            -- La Note Est Donnée par la Table Sonore Choisie
            --  Le Choix se Fait Grâce à SOURCE
            note <= data;
        end if;
    end process;

    
    -- Gestion du Compteur Mesurant la Durée d'une Note
    process(clk,not_reset)
    begin
        
        if not_reset = '0' then
            d_counter <= (others =>'0');
        elsif rising_edge(clk) then
            if (enable = '1') and (d_counter < duration) then
                d_counter <= d_counter + 1;
            else
                d_counter <= (others => '0');
            end if;
        end if;
    end process;
    
    -- Drapeau de Changement de Note
    change_note <= '1' when d_counter = duration else '0';

    -- Extraction des Paramètres de la Note --> Tonalité
    with note(8 downto 6) select
        pitch <= "1101110111110010001" when "001", --  110 Hz
                 "0110111011111001000" when "010", --  220 Hz
                 "0011011101111100100" when "011", --  440 Hz
                 "0001101110111110010" when "100", --  880 Hz
                 "0000110111011111001" when "101", -- 1760 Hz
                 "0000011011101111100" when "110", -- 3520 Hz
                 "0000001101110111110" when "111", -- 7040 Hz
                 "0000000000000000000" when others;

    -- Extraction des Paramètres de la Note --> Durée
    with note(5 downto 3) select
        duration <= "00000010111110101111000010" when "001", -- 1/64
                    "00000101111101011110000100" when "010", -- 1/32
                    "00001011111010111100001000" when "011", -- 1/16
                    "00010111110101111000010000" when "100", -- 1/8
                    "00101111101011110000100000" when "101", -- 1/4
                    "01011111010111100001000000" when "110", -- 1/2
                    "10111110101111000010000000" when "111", -- 1/1
                    "00000000000000000000000000" when others;

    -- Extraction des Paramètres de la Note --> Volume
    volume <= note(2 downto 0);


    -- Table Sonore Tir de Missile
    shooting:
        entity work.shooting_sound(content)
        port map(
            addr => note_addr,
            data => data_1
        );

    -- Table Sonore Explosion
    explosion:
        entity work.explosion_sound(content)
        port map(
            addr => note_addr,
            data => data_2
        );

    -- Sélection de la Table à Lire
    data <= data_1 when source = '0' else data_2;

    -- Instanciation du Générateur de Signal Sonore
    sounds:
        entity work.sounds(generator)
        port map(
            clk => clk, not_reset => not_reset,
            enable => enable,
            period => pitch,
            volume => volume,
            buzzer => buzzer
        );

end behaviour;

