LIBRARY       IEEE; 
USE           IEEE.STD_LOGIC_1164.ALL;
use           ieee.std_logic_unsigned.all;
use           IEEE.NUMERIC_STD.all;

entity avalon_anemometre is 
port (

 --ENTRES---
 clk:					in std_logic;
 chipselect:		in std_logic;
 write_n:			in std_logic;
 reset_n:			in std_logic;
 writedata:			in std_logic_vector (31 downto 0);
 
 FREQ_IN:			in std_logic; -- FREQUENCE DU VENT 
 
 --SORTIES---
 readdata: 			out std_logic_vector( 31 downto 0 );	
 --ENTRES-----SORTIES---
 address: 			std_logic_vector (1 downto 0)
 );

end avalon_anemometre;

architecture behavior of avalon_anemometre is
--signal cpt0 : 	std_logic_vector (15 downto 0); -- Compteur par rapport l'horloge (pour faire 1 ms)

signal DATA : 				std_logic_vector( 7 downto 0 ); -- SIGNAL DE FREQUENCE MESURE DE 0 A 250HZ
signal Data_valid : 		std_logic; -- SIGNAL DONNE PRET 
Signal c:					std_logic; -- SIGNAL CONTINUE (MODO AUTONOME)
Signal Start_Stop:		std_logic; -- SIGNAL START_STOP (MODO MANUEL)


signal cpt0	:  integer range 0 to 50000000:=0;
signal c0 : 	std_logic_vector (7 downto 0); -- Compteur prenant en compte le nombre de pulsations
signal sec : 	std_logic:='0'; -- Signal permettant de commuter entre l'horloge et la fr�quence 
signal Asec:	std_logic:='0'; -- Singnal permettant de active le compteur de secondes par le mode automatique
type Etat is (Etat0, Etat1, Etat2); --Definition des etats de la machinie
Signal Etat_present, Etat_futur : Etat := Etat0; --etats

begin

Sequentiel_maj_etat : process (clk,reset_n)

begin

	if reset_n = '0' then
	Etat_present <= Etat0;
	elsif clk'event and clk = '1' then
	Etat_present <= Etat_futur;
	end if;
	
end process Sequentiel_maj_etat;


Combinatoire_etats : process (c, sec, start_stop, Etat_present)

begin

	case Etat_present is
	
		when Etat0 => if c = '1' then
		Etat_futur <= Etat1;
		elsif c = '0' and start_stop = '1' then 
		Etat_futur <= Etat2;
		else
		Etat_futur <= Etat0;
		end if;
		
		when Etat1 => if c = '0' then
		Etat_futur <= Etat0;
		elsif c = '1' and sec = '1' then
		Etat_futur <= Etat2;
		else 
		Etat_futur <= Etat1;
		end if;
		
		when Etat2 => if c = '0' then
		Etat_futur <= Etat0;
		elsif c = '1'  then
		Etat_futur <= Etat1;
		else 
		Etat_futur <= Etat2;
		end if;
		
	end case;

end process Combinatoire_etats;

Combinatoire_sorties : process (Etat_present)

begin

	case Etat_present is
		when Etat0 =>  Asec <= '0'; Data_valid<='0'; 
		when Etat1 =>  Asec <= '1'; Data_valid<='0';
		when Etat2 =>  Asec <= '0'; Data_valid<='1'; 
	end case;

end process Combinatoire_sorties;

seq : process (clk, Reset_n, Asec)
begin
 if reset_n='0'  then
 cpt0<=0; -- Le reset doit étre asynchrone par rapport ? l'horloge
 sec <='0';
 elsif  Asec='1' then
 cpt0<=0;
 elsif clk'event and clk='1' then
 if cpt0 = 50000 then --on compte une microseconde
 cpt0<=0;
 sec <= '1';
 else
 cpt0<=cpt0+1; -- Activation du compteur pour avoir 1 us
 sec<='0';
 end if;
 end if;
end process;

--------------------------------------------------------------------------------
--
-- Processus du compteur de frequence
--
--------------------------------------------------------------------------------
diviseur : process (FREQ_IN, reset_n)
begin
 if (reset_n='0') then
 c0<= (others => '0');
 -- Activation du signal frequence sur front montant
 elsif FREQ_IN'event and FREQ_IN = '1' then
 if c0 < "11111111" then
 c0 <= c0 + 1 ; -- On compte le nombre de pulsations sur 1 us
 else
 c0 <= "11111111";  
 end if;
 end if;
end process diviseur;

gestion_sorti: process(Data_valid)
begin
if Data_valid = '1' then
DATA <= c0;
end if;
end process gestion_sorti;

--INTEFACE LECTURE REGISTRES

process_Read:PROCESS(address)
 BEGIN
 case address is
 when "00" => readdata <= "0000000000000000000000" & data_valid & '0' & DATA ;
			  --readdata(31 downto 10) <= (others => '0');
 when others => readdata <= (others => '0');
 end case;
 END PROCESS process_Read ;

end behavior;