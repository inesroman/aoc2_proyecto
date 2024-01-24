library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; -- se usa para convertir std_logic a enteros
entity Via is 
 	generic ( num_via: integer); -- se usa para los mensajes. Hay que poner el n�mero correcto al instanciarla
 	port (	CLK : in std_logic;
			reset : in  STD_LOGIC;
 			Dir_word: in std_logic_vector(1 downto 0); -- se usa para elegir la palabra a la que se accede en un conjunto la cache de datos. 
 			Dir_cjto: in std_logic_vector(1 downto 0); -- se usa para elegir el conjunto
 			Tag: in std_logic_vector(25 downto 0);
 			Din : in std_logic_vector (31 downto 0);
			RE : in std_logic;		-- read enable		
			WE : in  STD_LOGIC; 	-- write enable	
			Tags_WE : in  STD_LOGIC; 	-- write enable para la memoria de etiquetas 
			hit : out STD_LOGIC; -- indica si es acierto
			Dout : out std_logic_vector (31 downto 0)) ;
end Via;
 			
Architecture Behavioral of Via is

component reg is
    generic (size: natural := 32);  -- por defecto son de 32 bits, pero se puede usar cualquier tama�o
	Port ( Din : in  STD_LOGIC_VECTOR (size -1 downto 0);
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (size -1 downto 0));
end component;

-- definimos la memoria de contenidos de la cache de datos como un array de 16 palabras de 32 bits
type Ram_MC_data is array(0 to 15) of std_logic_vector(31 downto 0);
signal MC_data : Ram_MC_data := (  		X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- posiciones 0,1,2,3,4,5,6,7
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000");									
-- definimos la memoria de etiquetas de la cache de datos como un array de 4 palabras de 26 bits
type Ram_MC_Tags is array(0 to 3) of std_logic_vector(25 downto 0);
signal MC_Tags : Ram_MC_Tags := (  		"00000000000000000000000000", "00000000000000000000000000", "00000000000000000000000000", "00000000000000000000000000");												
signal valid_bits_in, valid_bits_out, mask: std_logic_vector(3 downto 0); -- se usa para saber si un bloque tiene info v�lida. Cada bit representa un bloque.									
signal valid_bit: std_logic;
signal Dir_MC: std_logic_vector(3 downto 0); -- se usa para leer/escribir las datos almacenas en al MC. 
signal MC_Tags_Dout: std_logic_vector(25 downto 0); 

begin 
-------------------------------------------------------------------------------------------------- 
-----memoria_cache_D: memoria RAM que almacena los 4 bloques de 4 datos que puede guardar la Cache
-------------------------------------------------------------------------------------------------- 
Dir_MC <= Dir_cjto&Dir_word;
 memoria_cache_D: process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (WE = '1') then -- s�lo se escribe si WE vale 1
                MC_data(conv_integer(Dir_MC)) <= Din;
				-- report saca un mensaje en la consola del simulador.  Nos imforma sobre qu� dato se ha escrito, d�nde y cu�ndo
				report "Simulation time : " & time'IMAGE(now) & ".  Data written in via " & integer'image(num_via) & ": " & integer'image(to_integer(unsigned(Din))) & ", in Dir_cjto = " & integer'image(to_integer(unsigned(Dir_cjto)));
            end if;
        end if;
    end process;
    Dout <= MC_data(conv_integer(Dir_MC)) when (RE='1') else "00000000000000000000000000000000"; --s�lo se lee si RE_MC vale 1
-------------------------------------------------------------------------------------------------- 
-----MC_Tags: memoria RAM que almacena las 4 etiquetas
-------------------------------------------------------------------------------------------------- 
memoria_cache_tags: process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (Tags_WE = '1') then -- s�lo se escribe si Tags_WE vale 1
                MC_Tags(conv_integer(dir_cjto)) <= Tag;
				-- report saca un mensaje en la consola del simulador. Nos imforma sobre qu� etiqueta se ha escrito, d�nde y cu�ndo
				report "Simulation time : " & time'IMAGE(now) & ".  Tag written in via " & integer'image(num_via) & ": " & integer'image(to_integer(unsigned(Tag))) & ", in Dir_cjto = " & integer'image(to_integer(unsigned(dir_cjto)));
            end if;
        end if;
    end process;
    MC_Tags_Dout <= MC_Tags(conv_integer(dir_cjto)); --s�lo se lee si RE_MC vale 1
-------------------------------------------------------------------------------------------------- 
-- registro de validez. Al resetear los bits de validez se ponen a 0 as� evitamos falsos positivos por basura en las memorias
-- en el bit de validez se escribe a la vez que en la memoria de etiquetas. Hay que poner a 1 el bit que toque y mantener los dem�s, para eso usamos una mascara generada por un decodificador
-------------------------------------------------------------------------------------------------- 
mask			<= 	"0001" when dir_cjto="00" else
						"0010" when dir_cjto="01" else
						"0100" when dir_cjto="10" else
						"1000" when dir_cjto="11" else
						"0000";
valid_bits_in <= valid_bits_out OR mask;
bits_validez: reg generic map (size => 4)	port map(	Din => valid_bits_in, clk => clk, reset => reset, load => Tags_WE, Dout => valid_bits_out);
-------------------------------------------------------------------------------------------------- 
valid_bit <= 	valid_bits_out(0) when dir_cjto="00" else
						valid_bits_out(1) when dir_cjto="01" else
						valid_bits_out(2) when dir_cjto="10" else
						valid_bits_out(3) when dir_cjto="11" else
						'0';
-------------------------------------------------------------------------------------------------- 
-- Se�al de hit: se activa cuando la etiqueta coincide y el bit de valido es 1
hit <= '1' when ((MC_Tags_Dout= Tag) AND (valid_bit='1'))else '0'; --comparador que compara el tag almacenado en MC con el de la direcci�n y si es el mismo y el bloque tiene el bit de v�lido activo devuelve un 1
-------------------------------------------------------------------------------------------------- 

end Behavioral;