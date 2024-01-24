-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_unsigned.all;


  ENTITY testbench_MD_mas_MC IS
  END testbench_MD_mas_MC;

  ARCHITECTURE behavior OF testbench_MD_mas_MC IS 

  -- Component Declaration
  COMPONENT MD_mas_MC is port (
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
 end COMPONENT;

        SIGNAL clk, reset, RE, WE, Mem_ready, Data_abort :  std_logic;
        signal ADDR, Din, Dout, IO_input : std_logic_vector (31 downto 0);
        signal test_id : std_logic_vector (7 downto 0); --Para saber por qué prueba vamos
       
			           
  -- Clock period definitions
   constant CLK_period : time := 10 ns;
  BEGIN

  -- Component Instantiation
   uut: MD_mas_MC PORT MAP(clk=> clk, reset => reset, ADDR => ADDR, Din => Din, RE => RE, WE => WE, IO_input => IO_input, Mem_ready => Mem_ready, Data_abort=> Data_abort, Dout => Dout);

-- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;

 stim_proc: process
   		 variable done: integer :=0; -- la vamos a usar para la simulación
 	begin		
      		
    	reset <= '1';
    	--conv_std_logic_vector convierte el primer número (un 0) a un vector de tantos bits como se indiquen (en este caso 32 bits)
    	addr <= conv_std_logic_vector(0, 32);
  	   	Din <= conv_std_logic_vector(0, 32);
		-- IO_input. Lo voy a ir cambiando para que se vea como cambia en el scratch
  	   	IO_input <= conv_std_logic_vector(1024, 32);
  	   	RE <= '0';
		WE <= '0';
	  	wait for 20 ns;	
	  	--Test 0---------------------------------------------------------------------------------------------------------
	  	-- Debe ser un fallo de lectura. Traemos: 1,2,3 y 4 al cjto 0 via 0. Mandamos al mips la primera palabra (un 1)
	  	test_id <= conv_std_logic_vector(0, 8); --Test 0
	  	reset <= '0';
	  	RE <= '1';
	  	Addr <= conv_std_logic_vector(64, 32); 
	  	-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 1---------------------------------------------------------------------------------------------------------
		test_id <= conv_std_logic_vector(1, 8); --Test 1
      	Addr <= conv_std_logic_vector(68, 32); --Debe ser un acierto de lectura. Devolvemos un 2 al procesador
	  	-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 2---------------------------------------------------------------------------------------------------------
		--Debe ser un acierto de escritura. Escribimos FF en @18 y en la tercera palabra del bloque de MC del cjto 0 via 0
		test_id <= conv_std_logic_vector(2, 8); --Test 2
		-- IO_input. Segundo valor, para ver cómo cambia
		IO_input <= conv_std_logic_vector(2048, 32);
		Addr <= conv_std_logic_vector(72, 32); 
		Din <= conv_std_logic_vector(255, 32);
		RE <= '0';
		WE <= '1';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 3---------------------------------------------------------------------------------------------------------
		--Debe ser un fallo de escritura. Hay que traer el bloque con etiqueta 1 al cjto 2 via 0 (5,6,7,8) y escribir FF en la palabra 0 y en memoria en la palabra 24
		test_id <= conv_std_logic_vector(3, 8); --Test 3
		Addr <= conv_std_logic_vector(96, 32); 
		Din <= conv_std_logic_vector(255, 32);
		RE <= '0';
		WE <= '1';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 4---------------------------------------------------------------------------------------------------------
		--Debe ser un acierto de escritura. Escribimos FE en memoria en memoria en la palabra 24 y en la palabra 0 del conjunto 2 de la via 2
		test_id <= conv_std_logic_vector(4, 8); --Test 4
		Din <= conv_std_logic_vector(254, 32);
		Addr <= conv_std_logic_vector(96, 32); 
		RE <= '0';
		WE <= '1';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 5---------------------------------------------------------------------------------------------------------
		--Debe ser un fallo de lectura y almacenarse 9, 10, 11 y 12 en el cjto 0 en la via 1
		test_id <= conv_std_logic_vector(5, 8); --Test 5
		-- IO_input. Tercer valor 
		IO_input <= conv_std_logic_vector(4096, 32);
		Addr <= conv_std_logic_vector(128, 32); 
		RE <= '1';
		WE <= '0';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 6---------------------------------------------------------------------------------------------------------
		--Debe ser acierto de lectura
		test_id <= conv_std_logic_vector(6, 8); --Test 6
		Addr <= conv_std_logic_vector(64, 32); --Debe ser acierto de lectura. Devolvemos un 1 al MIPS
		RE <= '1';
		WE <= '0';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 7---------------------------------------------------------------------------------------------------------
		--Debe ser fallo de lectura y reemplazar el cjto 0 de la via 0. Traemos c,d,e,f. Mandamos C al MIPS
		test_id <= conv_std_logic_vector(7, 8); --Test 7
		Addr <= conv_std_logic_vector(256, 32); 
		RE <= '1';
		WE <= '0';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 8---------------------------------------------------------------------------------------------------------
		--Debe ser fallo de lectura y reemplazar el cjto 0 de la via 1. Traemos x10,x11,x12,x13. Mandamos x10 al MIPS
		test_id <= conv_std_logic_vector(8, 8); --Test 8
		Addr <= conv_std_logic_vector(192, 32); 
		RE <= '1';
		WE <= '0';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 9---------------------------------------------------------------------------------------------------------
		--Escritura en la memoria scratch (no cacheable). Se debe escribir 0xFE(254) en la palabra 1
		test_id <= conv_std_logic_vector(9, 8); --Test 9
		Din <= conv_std_logic_vector(254, 32);
		Addr <= x"10000004"; --Escritura en la memoria scratch (no cacheable). 
		RE <= '0';
		WE <= '1';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 10---------------------------------------------------------------------------------------------------------
		--Lectura de la memoria scratch (no cacheable). Se debe leer FE de la palabra 1
		test_id <= conv_std_logic_vector(10, 8); --Test 10
		Addr <= x"10000004"; 
		RE <= '1';
		WE <= '0';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 11---------------------------------------------------------------------------------------------------------
		--Leemos el valor que ha escrito Master_IO. El último es 4096
		test_id <= conv_std_logic_vector(11, 8); 
		Addr <= x"10000000"; 
		RE <= '1';
		WE <= '0';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 12---------------------------------------------------------------------------------------------------------
		--Fallo de lectura, pero la dirección está fuera de rang. Cuand el contolador la pidaa través del bus nadie responderá y se generará un error de memoria
		-- la dirección de la palabra se almacenará en el registro interno de MC
		test_id <= conv_std_logic_vector(12, 8); 
		Addr <= x"01110000"; 
		RE <= '1';
		WE <= '0';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
	  	--Test 13---------------------------------------------------------------------------------------------------------
		--Pedimos la dirección del registro interno de MC
		--Debe pasar de estado memory_error a No_error y desactivarse la señal data abort. Leemos la dirección x"01110000" (17891328)
		test_id <= conv_std_logic_vector(13, 8); 
		Addr <= x"01000000"; 
		RE <= '1';
		WE <= '0';
		-- Esperamos a que la memoria esté preparada para atender otra solicitud
	  	-- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante. 
        -- si esperamos un ns desaparecerá el pulso espureo, pero no el real
	  	done := 0;
        wait for 1 ns;
	  	while done < 1 loop
        	if Mem_ready = '0' then 
				wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
        		wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		else
	  		 	wait for 1 ns; -- para evitar avanzar en pulsos espurios
        		if Mem_ready ='1' then
	  				done := 1;
	  			end if;
	  		end if;
	  	end loop;
    	wait until clk'event;
    	wait until clk'event;--esperamos al siguiente pulso de reloj
		--Test 255---------------------------------------------------------------------------------------------------------
		--FIN
		--Nos quedamos pidiendo todo el rato el mismo valor a la memoria scratch. 
		--Se puede ver como una y otra vez habrá que esperar a que la memoria lo envie. Ya que al no ser cacheable no se almacena en MC
	  	test_id <= conv_std_logic_vector(255, 8); 
		Addr <= x"10000000"; 
		RE <= '1';
		WE <= '0';
	  	wait;
	  	
   end process;


  END;
