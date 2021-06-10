library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity voice_glue is

port (
   -- The voice --------------------------------------------------------
    clk750k      : in    std_logic;
    clk2m5       : in    std_logic;

    snd_voice_o     : out signed(15 downto 0);
	 
	 cart_wr_n_i     : in std_logic;
	 cart_cs_i		  : in std_logic;
	 res_n_i         : in std_logic;

    voice_enable    : in  std_logic;
    voice_addr      : in std_logic_vector(7 downto 0);
	 voice_d5        : in std_logic;
	 voice_ldq       : in std_logic;
	 voice_ald       : out std_logic
  );

end voice_glue;


 -----------------------------------------------------------------------------
  -- The Voice Module
  -- Victor Trucco - 07/2019
  -----------------------------------------------------------------------------
  
  architecture struct of voice_glue  is

  
  -- The Voice
  signal sp0256_ldq : std_logic;
  signal sp0256_load : std_logic;
  signal sp0256_fifo_we : std_logic;
  signal sp0256_p14 : std_logic;
  signal sp0256_wr  : std_logic := '1';
  signal sp0256_rst : std_logic := '1';
  signal sp0256_ff  : std_logic := '1';
  signal sp0256_ff_n  : std_logic := '1';
  signal cart_do_s : std_logic_vector(7 downto 0);
  signal sp0256_di : std_logic_vector(6 downto 0);
  signal sp0256_do : std_logic_vector(6 downto 0);
  signal cpu_t0_s  : std_logic := '0';
  signal SP0256_trig : std_logic := '0';
  signal SP0256_trig_ff : std_logic := '0';
  signal fifo_empty_s : std_logic;
  signal stage : integer := 1;

  begin
  sp0256_ff_n <= not sp0256_ff;
  
  
  process (sp0256_ff)
  begin
    if rising_edge(sp0256_ff) then
        sp0256_rst <= voice_d5;
        sp0256_di <= voice_addr(6 downto 0);     
    end if;
  end process;

  process (clk2m5)
  begin
    if rising_edge(clk2m5) then
        if voice_addr(7) = '1' and cart_wr_n_i = '0' and cart_cs_i = '0' and res_n_i = '1' and voice_enable = '1' then
          sp0256_ff <= '0';
        else 
          sp0256_ff <= '1';
        end if;

        sp0256_fifo_we <= sp0256_ff;
        
        if fifo_empty_s = '1' then 
          sp0256_load <= '0';
        else
          sp0256_load <= sp0256_ldq;
        end if;
             
        case (stage) is
        
          when 1 =>
            sp0256_trig <= '0'; 
            
            if fifo_empty_s = '0' and sp0256_ldq = '1' then -- tem algo para tocar and SP free?
              stage <= 2;
            end if;
            
          when 2 =>
            sp0256_trig <= '1'; 
            stage <= 3;
          
          when 3 =>
            if sp0256_ldq = '0' then 
              sp0256_trig <= '0'; 
              stage <= 1;
            end if;
          when others => stage <= 1;
        
        end case;
        
        sp0256_trig_ff <= sp0256_trig;
    end if;
  end process;
  
  
  sp0256 : entity work.sp0256
  port map
  (
    clock_750k      => clk750k,
	 clock_2m5       => clk2m5,
    reset           => not sp0256_rst, --reset a '1'! 
 
    input_rdy       => sp0256_ldq,  -- load request, is high when new allophone can be loaded
                      -- IC LOAD REQUEST. LRQ is a logic 1
                      --output whenever the input buffer is
                      --full. When LRQ goes to a logic 0, the input
                      --port may be loaded by placing the 8
                      --address bits on A1-A8 and pulsing the
                      --ALD output.
    
    allophone         => sp0256_do,
    trig_allophone  => sp0256_trig_ff, -- input: positive pulse to trigger
                          -- IC ADDRESS LOAD. A negative pulse on
                          -- this input loads the 8 address bits into
                          -- the input port. The negative edge of this
                          -- pulse causes LRQ to go high.
    
    audio_out       => snd_voice_o
      
  );
  
  fifo : entity work.fifo
  generic map
  (
    DATA_WIDTH  => 7,
    FIFO_DEPTH  => 64
  )
  port map 
  ( 
    clock_i     => clk2m5,
    reset_i     => not sp0256_rst, --not reset_n_s,
    
    -- input
    fifo_we_i   => sp0256_fifo_we,
    fifo_data_i   => sp0256_di,
    
    -- output
    fifo_read_i   => sp0256_load,
    fifo_data_o   => sp0256_do,

    -- flags
    fifo_empty_o  => fifo_empty_s,
    fifo_full_o   => open
  );


end struct;
