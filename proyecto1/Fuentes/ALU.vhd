-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.std_logic_arith.all;
--use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--se UNISIM.VComponents.all;

entity ALU is
    Port ( DA : in  STD_LOGIC_VECTOR (31 downto 0); --entrada 1
           DB : in  STD_LOGIC_VECTOR (31 downto 0); --entrada 2
           ALUctrl : in  STD_LOGIC_VECTOR (2 downto 0); -- función a realizar: 0 suma, 1 resta, 2 AND, 3 OR. El resto se dejan por si queremos añadir operaciones
           Dout : out  STD_LOGIC_VECTOR (31 downto 0)); -- salida
end ALU;

architecture Behavioral of ALU is

signal DA_internal, DB_internal, Dout_internal : unsigned(31 downto 0);
begin
    DA_internal <= unsigned(DA);
    DB_internal <= unsigned(DB);
    
    Dout_internal <= 	DA_internal + DB_internal when (ALUctrl = "000") 
        else DA_internal - DB_internal when (ALUctrl = "001") 
        else DA_internal AND DB_internal when (ALUctrl = "010")
        else DA_internal OR DB_internal when (ALUctrl = "011")
        else (others => '0');
    
    Dout <= std_logic_vector(Dout_internal);
end Behavioral;
    