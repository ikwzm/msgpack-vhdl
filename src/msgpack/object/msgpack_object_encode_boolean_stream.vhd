-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_boolean_stream.vhd
--!     @brief   MessagePack Object Encode to Boolean Stream
--!     @version 0.2.0
--!     @date    2016/6/19
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2015-2016 Ichiro Kawazome
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
entity  MsgPack_Object_Encode_Boolean_Stream is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 1;
        SIZE_BITS       :  positive := 32;
        I_JUSTIFIED     :  boolean  := TRUE;
        I_BUFFERED      :  boolean  := FALSE
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        START           : in  std_logic;
        SIZE            : in  std_logic_vector(SIZE_BITS  -1 downto 0);
        BUSY            : out std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Boolean/String Data Stream Input Interface
    -------------------------------------------------------------------------------
        I_START         : out std_logic;
        I_BUSY          : out std_logic;
        I_SIZE          : out std_logic_vector(SIZE_BITS-1 downto 0);
        I_DATA          : in  std_logic_vector(DATA_BITS-1 downto 0);
        I_STRB          : in  std_logic_vector(DATA_BITS-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic
    );
end MsgPack_Object_Encode_Boolean_Stream;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_Array;
use     MsgPack.PipeWork_Components.REDUCER;
architecture RTL of MsgPack_Object_Encode_Boolean_Stream is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_enable     :  std_logic;
    signal    intake_busy       :  std_logic;
    signal    intake_ready      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    value_data        :  std_logic_vector(CODE_WIDTH-1 downto 0);
    signal    value_strb        :  std_logic_vector(CODE_WIDTH-1 downto 0);
    signal    value_code        :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    value_last        :  std_logic;
    signal    value_valid       :  std_logic;
    signal    value_ready       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE       is (IDLE_STATE, SIZE_STATE, DATA_STATE);
    signal    curr_state        :  STATE_TYPE;
    signal    curr_count        :  unsigned(SIZE'length-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    INTAKE_BUFFERED: if (I_BUFFERED = TRUE or I_JUSTIFIED  = FALSE or  DATA_BITS /= CODE_WIDTH) generate
        function  to_integer(ARG:boolean) return integer is begin
            if (ARG) then return 1;
            else          return 0;
            end if;
        end function;
        constant  offeset      :  std_logic_vector(CODE_WIDTH-1 downto 0) := (others => '0');
    begin
        BUF: REDUCER                                    -- 
            generic map (                               -- 
                WORD_BITS       => 1                  , -- 1 bit
                STRB_BITS       => 1                  , -- 1 bit
                I_WIDTH         => DATA_BITS          , -- Input  Word Size
                O_WIDTH         => CODE_WIDTH         , -- Output Word Size
                QUEUE_SIZE      => 0                  , -- Queue depth auto
                VALID_MIN       => 0                  , -- VALID unused
                VALID_MAX       => 0                  , -- VALID unused
                O_VAL_SIZE      => CODE_WIDTH         , -- 
                O_SHIFT_MIN     => CODE_WIDTH         , -- SHIFT unused
                O_SHIFT_MAX     => CODE_WIDTH         , -- SHIFT unused
                I_JUSTIFIED     => to_integer(I_JUSTIFIED) , -- 
                FLUSH_ENABLE    => 0                    -- 
            )                                           -- 
            port map (                                  -- 
            -----------------------------------------------------------------------
            -- Clock and Reset Signals
            -----------------------------------------------------------------------
                CLK             => CLK                , -- In  :
                RST             => RST                , -- In  :
                CLR             => CLR                , -- In  :
            -----------------------------------------------------------------------
            -- Control and Status Signals
            -----------------------------------------------------------------------
                START           => '0'                , -- In  :
                OFFSET          => offeset            , -- In  :
                DONE            => '0'                , -- In  :
                FLUSH           => '0'                , -- In  :
                BUSY            => intake_busy        , -- Out :
                VALID           => open               , -- Out :
            -----------------------------------------------------------------------
            -- Byte Stream Input Interface
            -----------------------------------------------------------------------
                I_ENABLE        => intake_enable      , -- In  :
                I_STRB          => I_STRB             , -- In  :
                I_DATA          => I_DATA             , -- In  :
                I_DONE          => I_LAST             , -- In  :
                I_FLUSH         => '0'                , -- In  :
                I_VAL           => I_VALID            , -- In  :
                I_RDY           => intake_ready       , -- Out :
            -----------------------------------------------------------------------
            -- Byte Stream Output Interface
            -----------------------------------------------------------------------
                O_ENABLE        => '1'                , -- In  :
                O_DATA          => value_data         , -- Out :
                O_STRB          => value_strb         , -- Out :
                O_DONE          => value_last         , -- Out :
                O_FLUSH         => open               , -- Out :
                O_VAL           => value_valid        , -- Out :
                O_RDY           => value_ready        , -- In  :
                O_SHIFT         => "0"                  -- In  :
            );                                          --
        I_READY      <= intake_ready;                   -- 
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    INTAKE_THROUGH : if (I_BUFFERED = FALSE and I_JUSTIFIED = TRUE and DATA_BITS = CODE_WIDTH) generate
    begin
        value_data   <= I_DATA;
        value_strb   <= I_STRB;
        value_last   <= I_LAST;
        value_valid  <= I_VALID;
        I_READY      <= value_ready;
        intake_busy  <= '0';
        intake_ready <= value_ready;
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (value_data, value_strb, value_valid) begin
        for i in value_code'range loop
            if (value_valid = '1' and value_strb(i) = '1') then
                if (value_data(i) = '1') then
                    value_code(i) <= MsgPack_Object.New_Code_True;
                else
                    value_code(i) <= MsgPack_Object.New_Code_False;
                end if;
            else
                    value_code(i) <= CODE_NULL;
            end if;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ENCODE_ARRAY: MsgPack_Object_Encode_Array     -- 
        generic map (                             -- 
             CODE_WIDTH      => CODE_WIDTH      , --
             SIZE_BITS       => SIZE_BITS         -- 
        )                                         -- 
        port map (                                -- 
             CLK             => CLK             , -- In  :
             RST             => RST             , -- In  :
             CLR             => CLR             , -- In  :
             START           => START           , -- In  :
             SIZE            => SIZE            , -- In  :
             I_CODE          => value_code      , -- In  :
             I_LAST          => value_last      , -- In  :
             I_ERROR         => '0'             , -- In  :
             I_VALID         => value_valid     , -- In  :
             I_READY         => value_ready     , -- Out :
             O_CODE          => O_CODE          , -- Out :
             O_LAST          => O_LAST          , -- Out :
             O_ERROR         => O_ERROR         , -- Out :
             O_VALID         => O_VALID         , -- Out :
             O_READY         => O_READY           -- In  :
    );                                            -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    intake_enable <= '1' when (curr_state = START_STATE and to_01(curr_count) > 0) or
                              (curr_state = RUN_STATE  ) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST)
        function count_assert_bit(ARG:std_logic_vector) return integer is
            variable n  : integer range 0 to ARG'length;
            variable nL : integer range 0 to ARG'length/2;
            variable nH : integer range 0 to ARG'length-ARG'length/2;
            alias    a  : std_logic_vector(ARG'length-1 downto 0) is ARG;
        begin
            case a'length is
                when 0 =>                   n := 0;
                when 1 =>
                    if    (a =    "1") then n := 1;
                    else                    n := 0;
                    end if;
                when 2 =>
                    if    (a =   "11") then n := 2;
                    elsif (a =   "01") then n := 1;
                    elsif (a =   "10") then n := 1;
                    else                    n := 0;
                    end if;
                when 4 =>
                    if    (a = "1111") then n := 4;
                    elsif (a = "1110") then n := 3;
                    elsif (a = "1101") then n := 3;
                    elsif (a = "1100") then n := 2;
                    elsif (a = "1011") then n := 3;
                    elsif (a = "1010") then n := 2;
                    elsif (a = "1001") then n := 2;
                    elsif (a = "1000") then n := 1;
                    elsif (a = "0111") then n := 3;
                    elsif (a = "0110") then n := 2;
                    elsif (a = "0101") then n := 2;
                    elsif (a = "0100") then n := 1;
                    elsif (a = "0011") then n := 2;
                    elsif (a = "0010") then n := 1;
                    elsif (a = "0001") then n := 1;
                    else                    n := 0;
                    end if;
                when others =>
                    nL := count_assert_bit(a(a'length  -1 downto a'length/2));
                    nH := count_assert_bit(a(a'length/2-1 downto 0         ));
                    n  := nL + nH;
            end case;
            return n;
        end function;
    begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
                curr_count <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
                curr_count <= (others => '0');
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (START = '1') then
                            curr_state <= START_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                        curr_count <= unsigned(SIZE);
                    when START_STATE =>
                        if (curr_count > 0) then
                            curr_state <= RUN_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                    when RUN_STATE   =>
                        if (I_VALID = '1' and I_LAST = '1' and intake_ready = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= RUN_STATE;
                        end if;
                        if (I_VALID = '1' and intake_ready = '1') then
                            curr_count <= curr_count - count_assert_bit(I_STRB);
                        end if;
                    when others => 
                        curr_state <= IDLE_STATE;
                        curr_count <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    BUSY    <= '1' when (curr_state = RUN_STATE    or intake_busy = '1') else '0';
    I_START <= '1' when (curr_state = START_STATE and to_01(curr_count) >  0 ) else '0';
    I_BUSY  <= '1' when (curr_state = RUN_STATE) else '0';
    I_SIZE  <= std_logic_vector(curr_count);
end RTL;
