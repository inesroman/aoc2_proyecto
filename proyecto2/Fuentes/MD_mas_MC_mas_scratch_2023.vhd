----------------------------------------------------------------------------------
--
-- Description: Este módulo sustituye a la memoria de datos del mips. Incluye un memoria cache que se conecta a través de un bus a memoria principal
-- el interfaz añade una señal nueva (Mem_ready) que indica si la MC podrá ralizar la operación en el ciclo actual
----------------------------------------------------------------------------------
library IEEE;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
-- Memoria RAM de 128 palabras de 32 bits
entity MD_mas_MC is port (
		  CLK : in std_logic;
		  reset: in std_logic; 
		  ADDR : in std_logic_vector (31 downto 0); --Dir solicitada por el Mips
          Din : in std_logic_vector (31 downto 0);--entrada de datos desde el Mips
		  WE : in std_logic;		-- write enable	del MIPS
		  RE : in std_logic;		-- read enable del MIPS	
		  IO_input: in std_logic_vector (31 downto 0); --dato que viene de una entrada del sistema
		  Mem_ready: out std_logic; -- indica si podemos hacer la operación solicitada en el ciclo actual
		  Data_abort: out std_logic; --indica que el último acceso a memoria ha sido un error
		  Dout : out std_logic_vector (31 downto 0) --dato que se envía al Mips
		  ); 
end MD_mas_MC;

architecture Behavioral of MD_mas_MC is
-- Memoria de datos con su controlador de bus
component MD_cont is port (
		  CLK : in std_logic;
		  reset: in std_logic;
		  Bus_Frame: in std_logic; -- indica que el master quiere más datos
		  bus_last_word : in  STD_LOGIC; --indica que es el último dato de la transferencia
		  bus_Read: in std_logic;
		  bus_Write: in std_logic;
		  Bus_Addr : in std_logic_vector (31 downto 0); --Direcciones 
		  Bus_Data : in std_logic_vector (31 downto 0); --Datos 
          MD_Bus_DEVsel: out std_logic; -- para avisar de que se ha reconocido que la dirección pertenece a este módulo
		  MD_Bus_TRDY: out std_logic; -- para avisar de que se va a realizar la operación solicitada en el ciclo actual
		  MD_send_data: out std_logic; -- para enviar los datos al bus
                  MD_Dout : out std_logic_vector (31 downto 0)		  -- salida de datos
		  );
end component;

-- MemoriaCache de datos
COMPONENT MC_datos is port (
			CLK : in std_logic;
			reset : in  STD_LOGIC;
			--Interfaz con el MIPS
			ADDR : in std_logic_vector (31 downto 0); --Dir 
			Din : in std_logic_vector (31 downto 0);
			RE : in std_logic;		-- read enable		
			WE : in  STD_LOGIC; 
			ready : out  std_logic;  -- indica si podemos hacer la operación solicitada en el ciclo actual
			Dout : out std_logic_vector (31 downto 0); --dato que se envía al Mips
			-- Nueva señal de error
			Mem_ERROR: out std_logic; -- Se activa si en la ultima transferencia el esclavo no respondió a su dirección
			--Interfaz con el bus
			MC_Bus_Req: out  STD_LOGIC; --indica que la MC quiere usar el bus;
			MC_Bus_Grant: in  STD_LOGIC; --indica que el árbitro permite usar el bus a la MC;
			MC_Bus_Din : in std_logic_vector (31 downto 0);--para leer datos del bus
			Bus_TRDY : in  STD_LOGIC; --indica que el esclavo (la memoriade datos) puede realizar la operación solicitada en este ciclo
			Bus_DevSel: in  STD_LOGIC; --indica que la memoria ha reconocido que la dirección está dentro de su rango
			MC_send_addr_ctrl : out  STD_LOGIC; --ordena que se envíen la dirección y las señales de control al bus
			MC_send_data : out  STD_LOGIC; --ordena que se envíen los datos
			MC_frame : out  STD_LOGIC; --indica que la operación no ha terminado
			MC_last_word : out  STD_LOGIC; --indica que es el último dato de la transferencia
			MC_Bus_ADDR : out std_logic_vector (31 downto 0); --Dir 
			MC_Bus_data_out : out std_logic_vector (31 downto 0);--para enviar datos por el bus
			MC_bus_Rd_Wr : out  STD_LOGIC --'0' para lectura,  '1' para escritura
			 );
  END COMPONENT;
-- Memoria scratch (Memoria rápida que contesta en el ciclo en el que se le pide algo)
-- Sólo tiene acceso palabra a palabra
  COMPONENT MD_scratch is port (
		  CLK : in std_logic;
		  reset: in std_logic;
		  Bus_Frame: in std_logic; -- indica que el master quiere más datos
		  bus_Read: in std_logic;
		  bus_Write: in std_logic;
		  Bus_Addr : in std_logic_vector (31 downto 0); --Direcciones 
		  Bus_Data : in std_logic_vector (31 downto 0); --Datos  
		  MD_Bus_DEVsel: out std_logic; -- para avisar de que se ha reconocido que la dirección pertenece a este módulo
		  MD_Bus_TRDY: out std_logic; -- para avisar de que se va a realizar la operación solicitada en el ciclo actual
		  MD_send_data: out std_logic; -- para enviar los datos al bus
        MD_Dout : out std_logic_vector (31 downto 0)		  -- salida de datos
		  );
end COMPONENT;

COMPONENT Arbitro is
    Port ( 	clk : in  STD_LOGIC;
			reset : in  STD_LOGIC;
			last_word: in  STD_LOGIC; -- Cuando termina una transferencia cambiamos las prioridades
			bus_frame: in  STD_LOGIC;-- para saber que hay una transferenica en curso
			Bus_TRDY: in  STD_LOGIC; --para saber que la ultima transferencia va a realizarse este ciclo
    		Req0 : in  STD_LOGIC; -- hay dos solicitudes
           	Req1 : in  STD_LOGIC;
           	Grant0 : out std_LOGIC;
           	Grant1 : out std_LOGIC);
end COMPONENT;

COMPONENT IO_Master is
    Port ( 	clk: in  STD_LOGIC; 
		    reset: in  STD_LOGIC; 
			IO_M_bus_Grant: in std_logic; 
			IO_input: in STD_LOGIC_VECTOR (31 downto 0);
			bus_TRDY : in  STD_LOGIC; --indica que el esclavo no puede realizar la operación solicitada en este ciclo
			Bus_DevSel: in  STD_LOGIC; --indica que el esclavo ha reconocido que la dirección está dentro de su rango
			IO_M_ERROR: out std_logic; -- Se activa si el esclavo no responde a su dirección
			IO_M_Req: out std_logic; 
			IO_M_Read: out std_logic; 
			IO_M_Write: out std_logic;
			IO_M_bus_Frame: out std_logic; 
			IO_M_send_Addr: out std_logic;
			IO_M_send_Data: out std_logic;
			IO_M_last_word: out std_logic;
			IO_M_Addr: out STD_LOGIC_VECTOR (31 downto 0);
			IO_M_Data: out STD_LOGIC_VECTOR (31 downto 0)); 
end COMPONENT;

component counter is
 	generic (   size : integer := 10);
	Port ( clk : in  STD_LOGIC;
       reset : in  STD_LOGIC;
       count_enable : in  STD_LOGIC;
       count : out  STD_LOGIC_VECTOR (size-1 downto 0));
end component;

component reg is
    generic (size: natural := 32);  -- por defecto son de 32 bits, pero se puede usar cualquier tamaño
	Port ( Din : in  STD_LOGIC_VECTOR (size -1 downto 0);
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (size -1 downto 0));
end component;

--señales del bus
signal Bus_Data_Addr:  std_logic_vector(31 downto 0); 
signal Bus_TRDY, Bus_Devsel, bus_Read, bus_Write, Bus_Frame, Bus_last_word: std_logic;
--señales de MC
signal MC_Bus_Din, MC_Bus_ADDR, MC_Bus_data_out: std_logic_vector (31 downto 0);
signal MC_send_addr_ctrl, MC_send_data, MC_frame, MC_bus_Rd_Wr, MC_last_word: std_logic;
--señales de MD_scratch
signal MD_scratch_Dout:  std_logic_vector(31 downto 0); 
signal MD_scratch_Bus_DEVsel, MD_scratch_send_data, MD_scratch_Bus_TRDY: std_logic;
--señales de MD
signal MD_Dout:  std_logic_vector(31 downto 0); 
signal MD_Bus_DEVsel, MD_send_data, MD_Bus_TRDY: std_logic;
-- señales para el arbitraje
signal MC_Bus_Grant, MC_Bus_Req: std_logic;
signal IO_M_bus_Grant, IO_M_Req: std_logic;-- señales para simular otros dispositivos que solicitan el bus
--señales del máster de IO
signal IO_M_Addr, IO_M_Data:  std_logic_vector(31 downto 0); 
signal IO_M_read, IO_M_write, IO_M_last_word, IO_M_bus_Frame, IO_M_send_Addr, IO_M_send_Data, IO_M_ERROR: std_logic;
--señales de monitorización
signal IO_M_count: STD_LOGIC_VECTOR (7 downto 0);
-- señales de error
signal Mem_ERROR: std_logic;
begin
------------------------------------------------------------------------------------------------
--   MC de datos
------------------------------------------------------------------------------------------------

	MC: MC_datos PORT MAP(	clk=> clk, reset => reset, ADDR => ADDR, Din => Din, RE => RE, WE => WE, ready => Mem_ready, Dout => Dout, 
							MC_Bus_Din => MC_Bus_Din, Bus_TRDY => Bus_TRDY, Bus_DevSel => Bus_DevSel, MC_send_addr_ctrl => MC_send_addr_ctrl, 
							MC_send_data => MC_send_data, MC_frame => MC_frame, MC_Bus_ADDR => MC_Bus_ADDR, MC_Bus_data_out => MC_Bus_data_out, 
							MC_Bus_Req => MC_Bus_Req, MC_Bus_Grant => MC_Bus_Grant, MC_bus_Rd_Wr => MC_bus_Rd_Wr, MC_last_word => MC_last_word,
							Mem_ERROR => Mem_ERROR);

------------------------------------------------------------------------------------------------	
-- Controlador de MD
------------------------------------------------------------------------------------------------
	controlador_MD: MD_cont PORT MAP (
          CLK => CLK,
          reset => reset,
          Bus_Frame => Bus_Frame,
		  bus_last_word => bus_last_word,
          bus_Read => bus_Read,
		  bus_Write => bus_Write,
          Bus_Addr => Bus_Data_Addr,
	  	  Bus_data => Bus_Data_Addr,
          MD_Bus_DEVsel => MD_Bus_DEVsel,
          MD_Bus_TRDY => MD_Bus_TRDY,
          MD_send_data => MD_send_data,
          MD_Dout => MD_Dout
        );

------------------------------------------------------------------------------------------------	
-- Memoria Scratch de datos
------------------------------------------------------------------------------------------------
	M_scratch: MD_scratch PORT MAP (
          CLK => CLK,
          reset => reset,
          Bus_Frame => Bus_Frame,
          bus_Read => bus_Read,
			 bus_Write => bus_Write,
          Bus_Addr => Bus_Data_Addr,
	  	    Bus_data => Bus_Data_Addr,
          MD_Bus_DEVsel => MD_scratch_Bus_DEVsel,
          MD_Bus_TRDY => MD_scratch_Bus_TRDY,
          MD_send_data => MD_Scratch_send_data,
          MD_Dout => MD_Scratch_Dout
        );

------------------------------------------------------------------------------------------------	 
	MC_Bus_Din <= Bus_Data_Addr;
------------------------------------------------------------------------------------------------	 
------------------------------------------------------------------------------------------------
--   	BUS: líneas compartidas y buffers triestado (cuando no se manda nada queda en estado "Z" de alta impedancia)
--		o OR cableada (cuando no se envía nada, el estado por defecto es "0")
--		MC actua de máster, MD de slave. Y simulamos que hay otros dispositivos haciendo cosas en el bus con "others". 
--		Estos otros dispositivos intentan usar el bus todo el tiempo, pero el árbitro va asignanado prioridades con un round-robin
------------------------------------------------------------------------------------------------
-- Data: Tres fuentes de datos: MC, MD, y "others" 
	Bus_Data_Addr <= 	MC_Bus_data_out when MC_send_data = '1' 	else 
					 	MD_Dout when MD_send_data = '1' 			else 
						MD_Scratch_Dout when MD_Scratch_send_data = '1' 	else 
						IO_M_Data when IO_M_send_Data = '1' 	else 
						"ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; 
-- Addr: la dirección la envía MC o "others"
	Bus_Data_Addr <= 	MC_Bus_ADDR when (MC_send_addr_ctrl='1') 	else 
						IO_M_Addr when (IO_M_send_Addr='1') 	else 
						"ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; 
	Bus_Data_Addr <= 	x"00000000" when ((MC_send_data = '0')and (MD_send_data = '0') and (MD_Scratch_send_data = '0') and (IO_M_send_Data = '0') and (MC_send_addr_ctrl='0') and (IO_M_send_Addr='0')) else 
						"ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; 
-- Ponemos un 00000000 como valor por defecto para que el simulador no saque sin parar mensajes diciendo que hay señales con valor 'Z'						
	--Control
	--********************************************************************
	bus_Read 	<= 	not(MC_bus_Rd_Wr) when (MC_send_addr_ctrl='1') else
							IO_M_read when (IO_M_send_Addr = '1') 			else--en este ejemplo "others" nunca lee
							'0';
	bus_Write  	<= 	MC_bus_Rd_Wr when (MC_send_addr_ctrl='1') else
							IO_M_write when (IO_M_send_Addr = '1') 			else--"others" escribe en una dirección fuera de rango. Es sólo para que se vea cuando usa el bus
							'0';
	
	Bus_Frame <= MC_frame or IO_M_bus_Frame; --el bus está ocupado si cualquiera de los dos másters lo está usando
	
	Bus_last_word <= 	MC_last_word 		when (MC_frame='1') else 
							IO_M_last_word 	when (IO_M_bus_Frame='1') ELSE
							'0';
	
-- Señales de las memorias	
	Bus_DevSel <= MD_Bus_DEVsel or MD_scratch_Bus_DEVsel; 
	Bus_TRDY <= MD_Bus_TRDY or MD_scratch_Bus_TRDY; 
	
-- Árbitraje
	
	Arbitraje: arbitro port map(clk => clk, reset => reset, Req0 => MC_Bus_Req, Req1 => IO_M_Req, Grant0 => MC_Bus_Grant, Grant1 => IO_M_bus_Grant, 
								Bus_Frame=> Bus_Frame, Bus_TRDY=> Bus_TRDY, last_word => Bus_last_word);
------------------------------------------------------------------------------------------------	
-- este contador nos dice cuantos ciclos han podido usar el máster de IO. 
-- Su objetivo es ver si liberamos el bus en cuanto se puede o si lo retenemos más de la cuenta
	
	cont_IO: counter 		generic map (size => 8)
						port map (clk => clk, reset => reset, count_enable => IO_M_bus_Grant, count => IO_M_count);	
------------------------------------------------------------------------------------------------	
-- Modulo_IO: una y otra vez escribe lo que haya en la entrada IO_M_input en la última palabra de la Scratch. Es una forma de hacer visible al procesador una entrada externa
-- Lo más habitual será que tuviese un registro direccionable, y que actuase como esclavo en el bus, en lugar de como máster. Pero lo hemos hecho así para que haya dos másters que compitan por el bus
	Modulo_IO: IO_Master port map(	clk => clk, reset => reset, 
														IO_M_Req => IO_M_Req, 
														IO_M_bus_Grant => IO_M_bus_Grant, 
														IO_M_bus_Frame=> IO_M_bus_Frame, 
														IO_input => io_input,
														IO_M_read => IO_M_read, 
														IO_M_write => IO_M_write,
														IO_M_Addr => IO_M_Addr,
														IO_M_Data => IO_M_Data,
														IO_M_ERROR => IO_M_ERROR,
														bus_trdy => bus_trdy,
														Bus_DevSel => Bus_DevSel,
														IO_M_send_Addr => IO_M_send_Addr,
														IO_M_send_Data => IO_M_send_Data,
														IO_M_last_word => IO_M_last_word);
	

------------------------------------------------------------------------------------------------	
-- Data abort 
 	Data_abort <= Mem_Error; --Si la memoria da un error avisamos al procesador activando data_abort

end Behavioral;

