-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_integer.vhd
--!     @brief   MessagePack Object decode to integer
--!     @version 0.1.0
--!     @date    2015/10/22
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2015 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
entity  MsgPack_Object_Decode_Integer is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE;
        QUEUE_SIZE      :  integer  := 0;
        CHECK_RANGE     :  boolean  := TRUE ;
        ENABLE64        :  boolean  := TRUE 
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack Object Code Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Output Interface
    -------------------------------------------------------------------------------
        O_VALUE         : out std_logic_vector(VALUE_BITS-1 downto 0);
        O_SIGN          : out std_logic;
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end  MsgPack_Object_Decode_Integer;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.PipeWork_Components.QUEUE_REGISTER;
architecture RTL of MsgPack_Object_Decode_Integer is
    signal   ii_sign     :  std_logic;
    signal   ii_value    :  std_logic_vector(63 downto 0);
    signal   ii_valid    :  std_logic_vector( 1 downto 0);
    signal   ii_shift    :  std_logic_vector( 1 downto 0);
    signal   ii_ready    :  std_logic;
    signal   done        :  boolean;
    signal   type_error  :  boolean;
    signal   range_error :  boolean;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    SHORT_VEC: if (CODE_WIDTH  < 2) generate
        type      STATE_TYPE    is (IDLE_STATE, INT64_STATE, UINT64_STATE);
        signal    curr_state    :  STATE_TYPE;
        signal    next_state    :  STATE_TYPE;
        signal    upper_value   :  std_logic_vector(31 downto 0);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (I_VALID, I_CODE, curr_state, ii_ready) begin
            if (I_VALID = '1' and I_CODE(0).valid = '1' and ii_ready = '1') then
                if     (ENABLE64   = TRUE) and
                       (curr_state = INT64_STATE) then
                    if (I_CODE(0).complete = '1') and
                       (I_CODE(0).class    = MsgPack_Object.CLASS_INT ) then
                        type_error <= FALSE;
                        done       <= TRUE;
                        ii_valid   <= "11";
                        ii_shift   <= "01";
                        next_state <= IDLE_STATE;
                    else
                        type_error <= TRUE;
                        done       <= TRUE;
                        ii_valid   <= "00";
                        ii_shift   <= "00";
                        next_state <= IDLE_STATE;
                    end if;
                elsif  (ENABLE64   = TRUE) and
                       (curr_state = UINT64_STATE) then
                    if (I_CODE(0).complete = '1') and
                       (I_CODE(0).class    = MsgPack_Object.CLASS_UINT) then
                        type_error <= FALSE;
                        done       <= TRUE;
                        ii_valid   <= "11";
                        ii_shift   <= "01";
                        next_state <= IDLE_STATE;
                    else
                        type_error <= TRUE;
                        done       <= TRUE;
                        ii_valid   <= "00";
                        ii_shift   <= "00";
                        next_state <= IDLE_STATE;
                    end if;
                elsif (I_CODE(0).complete = '0') then
                    if    (ENABLE64 = TRUE) and
                          (I_CODE(0).class = MsgPack_Object.CLASS_INT) then
                        type_error <= FALSE;
                        done       <= FALSE;
                        ii_valid   <= "00";
                        ii_shift   <= "01";
                        next_state <= INT64_STATE;
                    elsif (ENABLE64 = TRUE) and
                          (I_CODE(0).class = MsgPack_Object.CLASS_UINT) then
                        type_error <= FALSE;
                        done       <= FALSE;
                        ii_valid   <= "00";
                        ii_shift   <= "01";
                        next_state <= UINT64_STATE;
                    else
                        type_error <= TRUE;
                        done       <= TRUE;
                        ii_valid   <= "00";
                        ii_shift   <= "00";
                        next_state <= IDLE_STATE;
                    end if;
                else
                    if    (I_CODE(0).class = MsgPack_Object.CLASS_INT ) or
                          (I_CODE(0).class = MsgPack_Object.CLASS_UINT) then
                        type_error <= FALSE;
                        done       <= TRUE;
                        ii_valid   <= "01";
                        ii_shift   <= "01";
                        next_state <= IDLE_STATE;
                    else
                        type_error <= TRUE;
                        done       <= TRUE;
                        ii_valid   <= "00";
                        ii_shift   <= "00";
                        next_state <= IDLE_STATE;
                    end if;
                end if;
            else
                        type_error <= FALSE;
                        done       <= FALSE;
                        ii_valid   <= "00";
                        ii_shift   <= "00";
                        next_state <= curr_state;
            end if;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (curr_state, I_CODE, upper_value) begin
            if   (ENABLE64 = TRUE) and
                 ((curr_state = INT64_STATE ) or
                  (curr_state = UINT64_STATE)) then
                ii_value(31 downto  0) <= I_CODE(0).data;
                ii_value(63 downto 32) <= upper_value;
            elsif (I_CODE(0).class = MsgPack_Object.CLASS_INT) and
                  (I_CODE(0).data(31) = '1') then
                ii_value(31 downto  0) <= I_CODE(0).data;
                ii_value(63 downto 32) <= (63 downto 32 => '1');
            else
                ii_value(31 downto  0) <= I_CODE(0).data;
                ii_value(63 downto 32) <= (63 downto 32 => '0');
            end if;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    curr_state  <= IDLE_STATE;
                    upper_value <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    curr_state  <= IDLE_STATE;
                    upper_value <= (others => '0');
                else
                    curr_state  <= next_state;
                    if (next_state /= IDLE_STATE) then
                        upper_value <= I_CODE(0).data;
                    end if;
                end if;
            end if;
        end process;
        ii_sign <= '1' when (curr_state = IDLE_STATE and I_CODE(0).class = MsgPack_Object.CLASS_INT) or
                            (curr_state = INT64_STATE) else '0';
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    LONG_VEC:  if (CODE_WIDTH >= 2) generate
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (I_VALID, I_CODE) begin
            if (I_VALID = '1' and I_CODE(0).valid = '1') then
                if (I_CODE(0).class = MsgPack_Object.CLASS_INT ) or
                   (I_CODE(0).class = MsgPack_Object.CLASS_UINT) then
                    if (I_CODE(0).complete = '0') then
                        if    (ENABLE64 = FALSE) then
                            type_error <= TRUE;
                            done       <= TRUE;
                            ii_valid   <= "00";
                            ii_shift   <= "00";
                        elsif (I_CODE(1).valid = '0') then
                            type_error <= FALSE;
                            done       <= FALSE;
                            ii_valid   <= "00";
                            ii_shift   <= "00";
                        elsif (I_CODE(1).valid    = '1') and
                              (I_CODE(1).class    = I_CODE(0).class) and
                              (I_CODE(1).complete = '1') then
                            type_error <= FALSE;
                            done       <= TRUE;
                            ii_valid   <= "11";
                            ii_shift   <= "11";
                        else
                            type_error <= TRUE;
                            done       <= TRUE;
                            ii_valid   <= "00";
                            ii_shift   <= "00";
                        end if;
                    else
                            type_error <= FALSE;
                            done       <= TRUE;
                            ii_valid   <= "01";
                            ii_shift   <= "01";
                    end if;
                else
                            type_error <= TRUE;
                            done       <= TRUE;
                            ii_valid   <= "00";
                            ii_shift   <= "00";
                end if;
            else
                            type_error <= FALSE;
                            done       <= FALSE;
                            ii_valid   <= "00";
                            ii_shift   <= "00";
            end if;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (ii_valid, I_CODE) begin
            if    (ii_valid(1) = '1' and ENABLE64 = TRUE) then
                ii_value(31 downto  0) <= I_CODE(0).data;
                ii_value(63 downto 32) <= I_CODE(1).data;
            elsif (I_CODE(0).class = MsgPack_Object.CLASS_INT) and
                  (I_CODE(0).data(31) = '1') then
                ii_value(31 downto  0) <= I_CODE(0).data;
                ii_value(63 downto 32) <= (63 downto 32 => '1');
            else
                ii_value(31 downto  0) <= I_CODE(0).data;
                ii_value(63 downto 32) <= (63 downto 32 => '0');
            end if;
        end process;
        ii_sign <= '1' when (I_CODE(0).class = MsgPack_Object.CLASS_INT) else '0';
    end generate;
    -------------------------------------------------------------------------------
    -- range_error
    -------------------------------------------------------------------------------
    process (ii_value, ii_valid) begin
        range_error <= FALSE;
        if (CHECK_RANGE = TRUE and VALUE_BITS < 64 and ii_valid(0) = '1') then
            if (VALUE_SIGN) then
                for i in 63 downto VALUE_BITS loop
                    if (ii_value(i) /= ii_value(VALUE_BITS-1)) then
                        range_error <= TRUE;
                    end if;
                end loop;
            else
                for i in 63 downto VALUE_BITS loop
                    if (ii_value(i) /= '0') then
                        range_error <= TRUE;
                    end if;
                end loop;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- I_ERROR/I_DONE
    -------------------------------------------------------------------------------
    I_DONE  <= '1' when (done        = TRUE ) else '0';
    I_ERROR <= '1' when (type_error  = TRUE ) or
                        (range_error = TRUE ) else '0';
    -------------------------------------------------------------------------------
    -- I_SHIFT
    -------------------------------------------------------------------------------
    process (type_error, range_error, ii_shift) begin
        if (type_error = TRUE or range_error = TRUE) then
            I_SHIFT <= (others => '0');
        else
            for i in I_SHIFT'range loop
                if (i <= ii_shift'high) then
                    I_SHIFT(i) <= ii_shift(i);
                else
                    I_SHIFT(i) <= '0';
                end if;
            end loop;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    OUTLET: block
        constant  SIGN_POS  :  integer := VALUE_BITS + 0;
        constant  LAST_POS  :  integer := VALUE_BITS + 1;
        constant  DATA_BITS :  integer := VALUE_BITS + 2;
        signal    ii_data   :  std_logic_vector(DATA_BITS-1 downto 0);
        signal    oo_data   :  std_logic_vector(DATA_BITS-1 downto 0);
        signal    qq_valid  :  std_logic;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        ii_data(VALUE_BITS-1 downto 0) <= ii_value(VALUE_BITS-1 downto 0);
        ii_data(SIGN_POS             ) <= ii_sign;
        ii_data(LAST_POS             ) <= I_LAST;
        qq_valid <= '1' when (type_error  = FALSE) and
                             (range_error = FALSE) and
                             (ii_valid(0) = '1'  ) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        QUEUE: QUEUE_REGISTER                -- 
            generic map (                    -- 
                QUEUE_SIZE  => QUEUE_SIZE  , -- 
                DATA_BITS   => DATA_BITS   , -- 
                LOWPOWER    => 0             -- 
            )                                -- 
            port map (                       -- 
                CLK         => CLK         , -- In  :
                RST         => RST         , -- In  :
                CLR         => CLR         , -- In  :
                I_DATA      => ii_data     , -- In  :
                I_VAL       => qq_valid    , -- In  :
                I_RDY       => ii_ready    , -- Out :
                O_DATA      => open        , -- Out :
                O_VAL       => open        , -- Out :
                Q_DATA      => oo_data     , -- Out :
                Q_VAL(0)    => O_VALID     , -- Out :
                Q_RDY       => O_READY       -- In  :
            );                               --
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        O_VALUE <= oo_data(VALUE_BITS-1 downto 0);
        O_SIGN  <= oo_data(SIGN_POS);
        O_LAST  <= oo_data(LAST_POS);
    end block;
end RTL;
