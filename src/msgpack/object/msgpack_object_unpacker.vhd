-----------------------------------------------------------------------------------
--!     @file    msgpack_object_unpacker.vhd
--!     @brief   MessagePack Object Code Unpack from Byte Stream Module :
--!     @version 0.1.0
--!     @date    2015/10/19
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2012-2015 Ichiro Kawazome
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
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
entity  MsgPack_Object_Unpacker is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        I_BYTES         : positive := 1;
        CODE_WIDTH      : positive := 1;
        O_VALID_SIZE    : integer range 0 to 64 := 1;
        DECODE_UNIT     : integer range 0 to  3 := 1;
        SHORT_STR_SIZE  : integer range 0 to 31 := 8;
        STACK_DEPTH     : integer := 4
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Byte Stream Input Interface
    -------------------------------------------------------------------------------
        I_DATA          : in  std_logic_vector(           8*I_BYTES-1 downto 0);
        I_STRB          : in  std_logic_vector(             I_BYTES-1 downto 0);
        I_LAST          : in  std_logic := '0';
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
        O_SHIFT         : in  std_logic_vector(          CODE_WIDTH-1 downto 0)
    );
end MsgPack_Object_Unpacker;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.PipeWork_Components.REDUCER;
use     MsgPack.PipeWork_Components.CHOPPER;
use     MsgPack.MsgPack_Object_Components.MsgPack_Structure_Stack;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Reducer;
architecture RTL of MsgPack_Object_Unpacker is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   max(A,B:integer) return integer is begin
        if (A > B) then return A;
        else            return B;
        end if;
    end function;
    constant   BUFFER_BYTES      :  integer := max(9, (2**DECODE_UNIT)*4+1);
    constant   BUFFER_WORDS      :  integer := (BUFFER_BYTES+3)/4;
    constant   BUFFER_BITS       :  integer := 8*BUFFER_BYTES;
    signal     buffer_data       :  std_logic_vector(BUFFER_BITS -1 downto 0);
    signal     buffer_valid      :  std_logic_vector(BUFFER_BYTES-1 downto 0);
    signal     buffer_shift      :  std_logic_vector(BUFFER_BYTES-1 downto 0);
    signal     buffer_last       :  std_logic;
    signal     buffer_ready      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant   DECODE_WIDTH      :  integer := DECODE_UNIT+2;
    constant   DECODE_WORDS      :  integer := 2**(DECODE_UNIT  );
    constant   DECODE_BYTES      :  integer := 2**(DECODE_UNIT+2);
    constant   DECODE_BITS       :  integer := 2**(DECODE_UNIT+5);
    constant   LENGTH_BITS       :  integer := 32;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant   INTAKE_BYTES      :  integer := DECODE_BYTES+1;
    constant   INTAKE_DEPTH      :  integer := INTAKE_BYTES + DECODE_BYTES - 1;
    constant   intake_offset     :  std_logic_vector(  INTAKE_BYTES-1 downto 0) := (others => '0');
    signal     intake_shift      :  std_logic_vector(  INTAKE_BYTES-1 downto 0);
    signal     intake_valid      :  std_logic_vector(  INTAKE_BYTES-1 downto 0);
    signal     intake_data       :  std_logic_vector(8*INTAKE_BYTES-1 downto 0);
    signal     intake_last       :  std_logic;
    signal     intake_ready      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal     unpack_code       :  MsgPack_Object.Code_Vector(BUFFER_WORDS-1 downto 0);
    signal     unpack_valid      :  std_logic;
    signal     unpack_complete   :  std_logic;
    signal     unpack_last       :  std_logic;
    signal     object_length     :  unsigned(LENGTH_BITS-1 downto 0);
    signal     object_map        :  std_logic;
    signal     object_array      :  std_logic;
    signal     object_valid      :  std_logic;
    signal     stack_ready       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal     data_length_load  :  std_logic;
    signal     data_chop         :  std_logic;
    signal     data_length       :  unsigned(LENGTH_BITS-1 downto 0);
    signal     data_valid        :  std_logic_vector(DECODE_BYTES-1 downto 0);
    signal     data_last         :  std_logic;
    signal     data_none         :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal     outlet_valid      :  std_logic;
    signal     outlet_ready      :  std_logic;
    -------------------------------------------------------------------------------
    -- big-endian to little-endian function
    -----------------------------------------------------------------------
    function be_to_le(data: std_logic_vector) return std_logic_vector is
        alias    i_data : std_logic_vector(data'length-1 downto 0) is data;
    begin
        if    (data'length <=  8) then
            return i_data;
        elsif (data'length  = 16) then
            return i_data( 7 downto  0) &
                   i_data(15 downto  8) ;
        elsif (data'length  = 32) then
            return i_data( 7 downto  0) &
                   i_data(15 downto  8) &
                   i_data(23 downto 16) &
                   i_data(31 downto 24) ;
        elsif (data'length  = 64) then
            return i_data( 7 downto  0) &
                   i_data(15 downto  8) &
                   i_data(23 downto 16) &
                   i_data(31 downto 24) &
                   i_data(39 downto 32) &
                   i_data(47 downto 40) &
                   i_data(55 downto 48) &
                   i_data(63 downto 56) ;
        else
            assert FALSE report "be_to_le size error" severity FAILURE;
        end if;
    end function;
    -------------------------------------------------------------------------------
    -- big-endian to unsigned function
    -------------------------------------------------------------------------------
    function be_to_unsigned(data: std_logic_vector; length: integer) return unsigned is
    begin
        return resize(unsigned(be_to_le(data)), length);
    end function;
    -------------------------------------------------------------------------------
    -- big-endian to signed function
    -------------------------------------------------------------------------------
    function be_to_signed  (data: std_logic_vector; length: integer) return   signed is
        alias    i_data : std_logic_vector(data'length-1 downto 0) is data;
    begin
        return resize(  signed(be_to_le(data)), length);
    end function;
begin
    -------------------------------------------------------------------------------
    -- Input Byte Stream Buffer
    -------------------------------------------------------------------------------
    INTAKE: REDUCER                                 -- 
        generic map (                               -- 
            WORD_BITS       => 8                  , -- 1 byte(8bit)
            STRB_BITS       => 1                  , -- 1 bit
            I_WIDTH         => I_BYTES            , -- Input Byte Size
            O_WIDTH         => INTAKE_BYTES       , -- 
            QUEUE_SIZE      => INTAKE_DEPTH       , -- 
            VALID_MIN       => intake_valid'low   , -- 
            VALID_MAX       => intake_valid'high  , -- 
            O_VAL_SIZE      => 1                  , -- 
            O_SHIFT_MIN     => intake_shift'low   , -- 
            O_SHIFT_MAX     => intake_shift'high  , -- 
            I_JUSTIFIED     => 1                  , -- 
            FLUSH_ENABLE    => 0                    -- 
        )                                           -- 
        port map (                                  -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                , -- In  :
            RST             => RST                , -- In  :
            CLR             => CLR                , -- In  :
        ---------------------------------------------------------------------------
        -- Control and Status Signals
        ---------------------------------------------------------------------------
            START           => '0'                , -- In  :
            OFFSET          => intake_offset      , -- In  :
            DONE            => '0'                , -- In  :
            FLUSH           => '0'                , -- In  :
            BUSY            => open               , -- Out :
            VALID           => intake_valid       , -- Out :
        ---------------------------------------------------------------------------
        -- Byte Stream Input Interface
        ---------------------------------------------------------------------------
            I_ENABLE        => '1'                , -- In  :
            I_STRB          => I_STRB             , -- In  :
            I_DATA          => I_DATA             , -- In  :
            I_DONE          => I_LAST             , -- In  :
            I_FLUSH         => '0'                , -- In  :
            I_VAL           => I_VALID            , -- In  :
            I_RDY           => I_READY            , -- Out :
        ---------------------------------------------------------------------------
        -- Byte Stream Output Interface
        ---------------------------------------------------------------------------
            O_ENABLE        => '1'                , -- In  :
            O_DATA          => intake_data        , -- Out :
            O_STRB          => open               , -- Out :
            O_DONE          => intake_last        , -- Out :
            O_FLUSH         => open               , -- Out :
            O_VAL           => open               , -- Out :
            O_RDY           => intake_ready       , -- In  :
            O_SHIFT         => intake_shift         -- In  :
    );                                              --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    buffer_valid <= std_logic_vector(resize(unsigned(intake_valid), BUFFER_BYTES));
    buffer_data  <= std_logic_vector(resize(unsigned(intake_data ), BUFFER_BITS ));
    buffer_last  <= intake_last;
    intake_shift <= buffer_shift(INTAKE_BYTES-1 downto 0);
    intake_ready <= buffer_ready;
    -------------------------------------------------------------------------------
    -- Byte Code Parser
    -------------------------------------------------------------------------------
    PARSE: block
        type       STATE_TYPE   is (   FIRST_STATE,
                                    STR_DATA_STATE,
                                    BIN_DATA_STATE,
                                    EXT_DATA_STATE,
                                    EXT_TYPE_STATE,
                                     FLOAT64_STATE,
                                      UINT64_STATE,
                                       INT64_STATE);
        signal     next_state    :  STATE_TYPE;
        signal     curr_state    :  STATE_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (curr_state, buffer_valid, buffer_data, data_valid, data_last, data_none)
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            function  to_valid(size: integer; valid: std_logic_vector) return std_logic is
            begin
                if (valid(0) = '1' and valid(size-1) = '1') then
                    return '1';
                else
                    return '0';
                end if;
            end function;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            function  to_valid(need: std_logic_vector; valid: std_logic_vector) return std_logic is
                variable flag_vec  : std_logic_vector(need'range);
                constant FLAG_NULL : std_logic_vector(need'range) := (others => '0');
            begin
                for i in need'range loop
                    if (need(i) = '1' and valid(i) = '0') then
                        flag_vec(i) := '1';
                    else
                        flag_vec(i) := '0';
                    end if;
                end loop;
                if (flag_vec = FLAG_NULL) then
                    return '1';
                else
                    return '0';
                end if;
            end function;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            function  to_shift(size: integer) return std_logic_vector is
                variable shift : std_logic_vector(BUFFER_BYTES-1 downto 0);
            begin
                for i in shift'range loop
                    if (i < size) then
                        shift(i) := '1';
                    else
                        shift(i) := '0';
                    end if;
                end loop;
                return shift;
            end function;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            function  to_strb(size: integer) return std_logic_vector is
                variable strb  : std_logic_vector(DECODE_BYTES-1 downto 0);
            begin
                for i in strb'range loop
                    if (i < size) then
                        strb(i) := '1';
                    else
                        strb(i) := '0';
                    end if;
                end loop;
                return strb;
            end function;
            -----------------------------------------------------------------------
            -- 
            -----------------------------------------------------------------------
            procedure short_fixstr(constant size : in integer) is
            begin
                if (size <= DECODE_BYTES) then
                    unpack_code  <= MsgPack_Object.New_Code_Vector(
                        LENGTH   => BUFFER_WORDS,
                        CLASS    => MsgPack_Object.CLASS_STRING_DATA,
                        STRB     => to_strb(size),
                        DATA     => buffer_data(DECODE_BITS-1+8 downto 8),
                        COMPLETE => '1'
                    );
                    data_length  <= to_unsigned(size, LENGTH_BITS);
                    unpack_valid <= to_valid(size+1, buffer_valid);
                    buffer_shift <= to_shift(size+1);
                    next_state   <= FIRST_STATE;
                else
                    unpack_code  <= MsgPack_Object.New_Code_Vector(
                        LENGTH   => BUFFER_WORDS,
                        CLASS    => MsgPack_Object.CLASS_STRING_DATA,
                        STRB     => to_strb(DECODE_BYTES),
                        DATA     => buffer_data(DECODE_BITS-1+8 downto 8),
                        COMPLETE => '0'
                    );
                    data_length  <= to_unsigned(size-DECODE_BYTES, LENGTH_BITS);
                    unpack_valid <= to_valid(DECODE_BYTES+1, buffer_valid);
                    buffer_shift <= to_shift(DECODE_BYTES+1);
                    next_state   <= STR_DATA_STATE;
                end if;
            end procedure;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            variable  fixstr_size          :  integer range 0 to 31;
            variable  size_zero            :  boolean;
            variable  dummy_data_length    :  unsigned(data_length'range);
            variable  dummy_object_length  :  unsigned(object_length'range);
        begin
            if  (buffer_data(0) = '0') then
                dummy_object_length := be_to_unsigned(buffer_data(23 downto 8), LENGTH_BITS);
            else
                dummy_object_length := be_to_unsigned(buffer_data(39 downto 8), LENGTH_BITS);
            end if;
            dummy_data_length := (others => '0');
            unpack_code       <= (others => MsgPack_Object.CODE_NULL);
            case curr_state is
                -------------------------------------------------------------------
                -- Decode First State
                -------------------------------------------------------------------
                when FIRST_STATE =>
                    ---------------------------------------------------------------
                    -- positive fixint 0xxxxxxxx
                    ---------------------------------------------------------------
                    if    (buffer_data(7) = '0') then
                        unpack_code(0) <= MsgPack_Object.New_Code_Unsigned(
                            DATA       => unsigned(buffer_data(6 downto 0))
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- fixmap   1000xxxx
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 4) = "000") then
                        unpack_code(0) <= MsgPack_Object.New_Code_MapSize(
                            SIZE       => unsigned(buffer_data(3 downto 0))
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= be_to_unsigned(buffer_data(3 downto 0), LENGTH_BITS);
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- fixarray 1001xxxx
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 4) = "001") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ArraySize(
                            SIZE       => unsigned(buffer_data(3 downto 0))
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= be_to_unsigned(buffer_data(3 downto 0), LENGTH_BITS);
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- fixstr   101xxxxx
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 5) = "01") then
                        fixstr_size    := to_integer(to_01(unsigned(buffer_data(4 downto 0))));
                        object_length  <= be_to_unsigned(buffer_data(3 downto 0), LENGTH_BITS);
                        if    (fixstr_size =  1 and SHORT_STR_SIZE >=  1) then
                            short_fixstr(1);
                        elsif (fixstr_size =  2 and SHORT_STR_SIZE >=  2) then
                            short_fixstr(2);
                        elsif (fixstr_size =  3 and SHORT_STR_SIZE >=  3) then
                            short_fixstr(3);
                        elsif (fixstr_size =  4 and SHORT_STR_SIZE >=  4) then
                            short_fixstr(4);
                        elsif (fixstr_size =  5 and SHORT_STR_SIZE >=  5) then
                            short_fixstr(5);
                        elsif (fixstr_size =  6 and SHORT_STR_SIZE >=  6) then
                            short_fixstr(6);
                        elsif (fixstr_size =  7 and SHORT_STR_SIZE >=  7) then
                            short_fixstr(7);
                        elsif (fixstr_size =  8 and SHORT_STR_SIZE >=  8) then
                            short_fixstr(8);
                        elsif (fixstr_size =  9 and SHORT_STR_SIZE >=  9) then
                            short_fixstr(9);
                        elsif (fixstr_size = 10 and SHORT_STR_SIZE >= 10) then
                            short_fixstr(10);
                        elsif (fixstr_size = 11 and SHORT_STR_SIZE >= 11) then
                            short_fixstr(11);
                        elsif (fixstr_size = 12 and SHORT_STR_SIZE >= 12) then
                            short_fixstr(12);
                        elsif (fixstr_size = 13 and SHORT_STR_SIZE >= 13) then
                            short_fixstr(13);
                        elsif (fixstr_size = 14 and SHORT_STR_SIZE >= 14) then
                            short_fixstr(14);
                        elsif (fixstr_size = 15 and SHORT_STR_SIZE >= 15) then
                            short_fixstr(15);
                        elsif (fixstr_size = 16 and SHORT_STR_SIZE >= 16) then
                            short_fixstr(16);
                        elsif (fixstr_size = 17 and SHORT_STR_SIZE >= 17) then
                            short_fixstr(17);
                        elsif (fixstr_size = 18 and SHORT_STR_SIZE >= 18) then
                            short_fixstr(18);
                        elsif (fixstr_size = 19 and SHORT_STR_SIZE >= 19) then
                            short_fixstr(19);
                        elsif (fixstr_size = 20 and SHORT_STR_SIZE >= 20) then
                            short_fixstr(20);
                        elsif (fixstr_size = 21 and SHORT_STR_SIZE >= 21) then
                            short_fixstr(21);
                        elsif (fixstr_size = 22 and SHORT_STR_SIZE >= 22) then
                            short_fixstr(22);
                        elsif (fixstr_size = 23 and SHORT_STR_SIZE >= 23) then
                            short_fixstr(23);
                        elsif (fixstr_size = 24 and SHORT_STR_SIZE >= 24) then
                            short_fixstr(24);
                        elsif (fixstr_size = 25 and SHORT_STR_SIZE >= 25) then
                            short_fixstr(25);
                        elsif (fixstr_size = 26 and SHORT_STR_SIZE >= 26) then
                            short_fixstr(26);
                        elsif (fixstr_size = 27 and SHORT_STR_SIZE >= 27) then
                            short_fixstr(27);
                        elsif (fixstr_size = 28 and SHORT_STR_SIZE >= 28) then
                            short_fixstr(28);
                        elsif (fixstr_size = 29 and SHORT_STR_SIZE >= 29) then
                            short_fixstr(29);
                        elsif (fixstr_size = 30 and SHORT_STR_SIZE >= 30) then
                            short_fixstr(30);
                        elsif (fixstr_size = 31 and SHORT_STR_SIZE >= 31) then
                            short_fixstr(31);
                        elsif (fixstr_size = 0) then
                            unpack_code(0) <= MsgPack_Object.New_Code_StringSize(
                                SIZE     => to_unsigned(fixstr_size, 8)
                            );
                            data_length  <= to_unsigned(fixstr_size, LENGTH_BITS);
                            unpack_valid <= to_valid(1, buffer_valid);
                            buffer_shift <= to_shift(1);
                            next_state   <= FIRST_STATE;
                        else
                            unpack_code(0) <= MsgPack_Object.New_Code_StringSize(
                                SIZE     => to_unsigned(fixstr_size, 8)
                            );
                            data_length  <= to_unsigned(fixstr_size, LENGTH_BITS);
                            unpack_valid <= to_valid(1, buffer_valid);
                            buffer_shift <= to_shift(1);
                            next_state   <= STR_DATA_STATE;
                        end if;
                    ---------------------------------------------------------------
                    -- nil     11000000
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1000000") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Nil;
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- no used 11000001
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1000001") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Reserve;
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- false   11000010
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1000010") then
                        unpack_code(0) <= MsgPack_Object.New_Code_False;
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- true    11000011
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1000011") then
                        unpack_code(0) <= MsgPack_Object.New_Code_True;
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- bin 8   11000100
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1000100") then
                        size_zero      := (to_01(unsigned(buffer_data(15 downto 8))) = 0);
                        unpack_code(0) <= MsgPack_Object.New_Code_BinarySize(
                            SIZE       => be_to_unsigned(buffer_data(15 downto 8), 8)
                        );
                        unpack_valid   <= to_valid(2, buffer_valid);
                        buffer_shift   <= to_shift(2);
                        data_length    <= be_to_unsigned(buffer_data(15 downto 8), LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        if (size_zero) then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= BIN_DATA_STATE;
                        end if;
                    ---------------------------------------------------------------
                    -- bin 16  11000101
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1000101") then
                        size_zero      := (to_01(unsigned(buffer_data(23 downto 8))) = 0);
                        unpack_code(0) <= MsgPack_Object.New_Code_BinarySize(
                            SIZE       => be_to_unsigned(buffer_data(23 downto 8), 16)
                        );
                        unpack_valid   <= to_valid(3, buffer_valid);
                        buffer_shift   <= to_shift(3);
                        data_length    <= be_to_unsigned(buffer_data(23 downto 8), LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        if (size_zero) then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= BIN_DATA_STATE;
                        end if;
                    ---------------------------------------------------------------
                    -- bin 32  11000110
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1000110") then
                        size_zero      := (to_01(unsigned(buffer_data(39 downto 8))) = 0);
                        unpack_code(0) <= MsgPack_Object.New_Code_BinarySize(
                            SIZE       => be_to_unsigned(buffer_data(39 downto 8), 32)
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= be_to_unsigned(buffer_data(39 downto 8), LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        if (size_zero) then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= BIN_DATA_STATE;
                        end if;
                    ---------------------------------------------------------------
                    -- ext 8   11000111
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1000111") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtSize(
                            SIZE       => be_to_unsigned(buffer_data(15 downto 8), 8)
                        );
                        unpack_valid   <= to_valid(2, buffer_valid);
                        buffer_shift   <= to_shift(2);
                        data_length    <= be_to_unsigned(buffer_data(15 downto 8), LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        next_state     <= EXT_TYPE_STATE;
                    ---------------------------------------------------------------
                    -- ext 16  11001000
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1001000") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtSize(
                            SIZE       => be_to_unsigned(buffer_data(23 downto 8), 16)
                        );
                        unpack_valid   <= to_valid(3, buffer_valid);
                        buffer_shift   <= to_shift(3);
                        data_length    <= be_to_unsigned(buffer_data(23 downto 8), LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        next_state     <= EXT_TYPE_STATE;
                    ---------------------------------------------------------------
                    -- ext 32  11001001
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1001001") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtSize(
                            SIZE       => be_to_unsigned(buffer_data(39 downto 8), 32)
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= be_to_unsigned(buffer_data(39 downto 8), LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        next_state     <= EXT_TYPE_STATE;
                    ---------------------------------------------------------------
                    -- float32 11001010
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1001010") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Float(
                            DATA       => be_to_le(buffer_data(39 downto 8))
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- float64 11001011
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1001011" and DECODE_WORDS >= 2) then
                        unpack_code(0) <= MsgPack_Object.New_Code_Float(
                            DATA       => be_to_le(buffer_data(39 downto  8)),
                            COMPLETE   => '0'
                        );
                        unpack_code(1) <= MsgPack_Object.New_Code_Float(
                            DATA       => be_to_le(buffer_data(71 downto 40)),
                            COMPLETE   => '1'
                        );
                        unpack_valid   <= to_valid(9, buffer_valid);
                        buffer_shift   <= to_shift(9);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    elsif (buffer_data(6 downto 0) = "1001011" and DECODE_WORDS <  2) then
                        unpack_code(0) <= MsgPack_Object.New_Code_Float(
                            DATA       => be_to_le(buffer_data(39 downto  8)),
                            COMPLETE   => '0'
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FLOAT64_STATE;
                    ---------------------------------------------------------------
                    -- uint 8  11001100
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1001100") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Unsigned(
                            DATA       => be_to_unsigned(buffer_data(15 downto 8), 8)
                        );
                        unpack_valid   <= to_valid(2, buffer_valid);
                        buffer_shift   <= to_shift(2);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- uint 16 11001101
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1001101") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Unsigned(
                            DATA       => be_to_unsigned(buffer_data(23 downto 8), 16)
                        );
                        unpack_valid   <= to_valid(3, buffer_valid);
                        buffer_shift   <= to_shift(3);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- uint 32 11001110
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1001110") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Unsigned(
                            DATA       => be_to_unsigned(buffer_data(39 downto 8), 32)
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- uint 64 11001111
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1001111" and DECODE_WORDS >= 2) then
                        unpack_code(0) <= MsgPack_Object.New_Code_Unsigned(
                            DATA       => be_to_unsigned(buffer_data(39 downto  8), 32),
                            COMPLETE   => '0'
                        );
                        unpack_code(1) <= MsgPack_Object.New_Code_Unsigned(
                            DATA       => be_to_unsigned(buffer_data(71 downto 40), 32),
                            COMPLETE   => '1'
                        );
                        unpack_valid   <= to_valid(9, buffer_valid);
                        buffer_shift   <= to_shift(9);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    elsif (buffer_data(6 downto 0) = "1001111" and DECODE_WORDS <  2) then
                        unpack_code(0) <= MsgPack_Object.New_Code_Unsigned(
                            DATA       => be_to_unsigned(buffer_data(39 downto  8), 32),
                            COMPLETE   => '0'
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= UINT64_STATE;
                    ---------------------------------------------------------------
                    -- int 8   11010000
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1010000") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Signed(
                            DATA       => be_to_signed(buffer_data(15 downto 8), 8)
                        );
                        unpack_valid   <= to_valid(2, buffer_valid);
                        buffer_shift   <= to_shift(2);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- int 16  11010001
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1010001") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Signed(
                            DATA       => be_to_signed(buffer_data(23 downto 8), 16)
                        );
                        unpack_valid   <= to_valid(3, buffer_valid);
                        buffer_shift   <= to_shift(3);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- int 32  11010010
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1010010") then
                        unpack_code(0) <= MsgPack_Object.New_Code_Signed(
                            DATA       => be_to_signed(buffer_data(39 downto 8), 32)
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- int 64  11010011
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1010011" and DECODE_WORDS >= 2) then
                        unpack_code(0) <= MsgPack_Object.New_Code_Signed(
                            DATA       => be_to_unsigned(buffer_data(39 downto  8),32),
                            COMPLETE   => '0'
                        );
                        unpack_code(1) <= MsgPack_Object.New_Code_Signed(
                            DATA       => be_to_unsigned(buffer_data(71 downto 40),32),
                            COMPLETE   => '1'
                        );
                        unpack_valid   <= to_valid(9, buffer_valid);
                        buffer_shift   <= to_shift(9);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    elsif (buffer_data(6 downto 0) = "1010011" and DECODE_WORDS <  2) then
                        unpack_code(0) <= MsgPack_Object.New_Code_Signed(
                            DATA       => be_to_unsigned(buffer_data(39 downto  8),32),
                            COMPLETE   => '0'
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= INT64_STATE;
                    ---------------------------------------------------------------
                    -- fixext 1  11010100
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1010100") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtSize(
                            SIZE       => to_unsigned(1, 8)
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= to_unsigned(1, LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        next_state     <= EXT_TYPE_STATE;
                    ---------------------------------------------------------------
                    -- fixext 2  11010101
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1010101") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtSize(
                            SIZE       => to_unsigned(2, 8)
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= to_unsigned(2, LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        next_state     <= EXT_TYPE_STATE;
                    ---------------------------------------------------------------
                    -- fixext 4  11010110
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1010110") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtSize(
                            SIZE       => to_unsigned(4, 8)
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= to_unsigned(4, LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        next_state     <= EXT_TYPE_STATE;
                    ---------------------------------------------------------------
                    -- fixext 8  11010111
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1010111") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtSize(
                            SIZE       => to_unsigned(8, 8)
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= to_unsigned(8, LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        next_state     <= EXT_TYPE_STATE;
                    ---------------------------------------------------------------
                    -- fixext 16 11011000
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1011000") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtSize(
                            SIZE       => to_unsigned(16, 8)
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= to_unsigned(16, LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        next_state     <= EXT_TYPE_STATE;
                    ---------------------------------------------------------------
                    -- str 8    11011001
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1011001") then
                        size_zero      := (to_01(unsigned(buffer_data(15 downto 8))) = 0);
                        unpack_code(0) <= MsgPack_Object.New_Code_StringSize(
                            SIZE       => be_to_unsigned(buffer_data(15 downto 8), 8)
                        );
                        unpack_valid   <= to_valid(2, buffer_valid);
                        buffer_shift   <= to_shift(2);
                        data_length    <= be_to_unsigned(buffer_data(15 downto 8), LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        if (size_zero) then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= STR_DATA_STATE;
                        end if;
                    ---------------------------------------------------------------
                    -- str 16   11011010
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1011010") then
                        size_zero      := (to_01(unsigned(buffer_data(23 downto 8))) = 0);
                        unpack_code(0) <= MsgPack_Object.New_Code_StringSize(
                            SIZE       => be_to_unsigned(buffer_data(23 downto 8), 16)
                        );
                        unpack_valid   <= to_valid(3, buffer_valid);
                        buffer_shift   <= to_shift(3);
                        data_length    <= be_to_unsigned(buffer_data(23 downto 8), LENGTH_BITS);
                        object_length  <= dummy_object_length;
                        if (size_zero) then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= STR_DATA_STATE;
                        end if;
                    ---------------------------------------------------------------
                    -- str 32   11011011
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1011011") then
                        size_zero      := (to_01(unsigned(buffer_data(39 downto 8))) = 0);
                        unpack_code(0) <= MsgPack_Object.New_Code_StringSize(
                            SIZE       => be_to_unsigned(buffer_data(39 downto 8), 32)
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= be_to_unsigned(buffer_data(39 downto 8), LENGTH_BITS);
                        next_state     <= STR_DATA_STATE;
                        object_length  <= dummy_object_length;
                        if (size_zero) then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= STR_DATA_STATE;
                        end if;
                    ---------------------------------------------------------------
                    -- array 16 11011100
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1011100") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ArraySize(
                            SIZE       => be_to_unsigned(buffer_data(23 downto 8), 16)
                        );
                        unpack_valid   <= to_valid(3, buffer_valid);
                        buffer_shift   <= to_shift(3);
                        data_length    <= be_to_unsigned(buffer_data(23 downto 8), LENGTH_BITS);
                        object_length  <= be_to_unsigned(buffer_data(23 downto 8), LENGTH_BITS);
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- array 32 11011101
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1011101") then
                        unpack_code(0) <= MsgPack_Object.New_Code_ArraySize(
                            SIZE       => be_to_unsigned(buffer_data(39 downto 8), 32)
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= be_to_unsigned(buffer_data(39 downto 8), LENGTH_BITS);
                        object_length  <= be_to_unsigned(buffer_data(39 downto 8), LENGTH_BITS);
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- map 16   11011110
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1011110") then
                        unpack_code(0) <= MsgPack_Object.New_Code_MapSize(
                            SIZE       => be_to_unsigned(buffer_data(23 downto 8), 16)
                        );
                        unpack_valid   <= to_valid(3, buffer_valid);
                        buffer_shift   <= to_shift(3);
                        data_length    <= be_to_unsigned(buffer_data(23 downto 8), LENGTH_BITS);
                        object_length  <= be_to_unsigned(buffer_data(23 downto 8), LENGTH_BITS);
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- map 32   11011111
                    ---------------------------------------------------------------
                    elsif (buffer_data(6 downto 0) = "1011111") then
                        unpack_code(0) <= MsgPack_Object.New_Code_MapSize(
                            SIZE       => be_to_unsigned(buffer_data(39 downto 8), 32)
                        );
                        unpack_valid   <= to_valid(5, buffer_valid);
                        buffer_shift   <= to_shift(5);
                        data_length    <= be_to_unsigned(buffer_data(39 downto 8), LENGTH_BITS);
                        object_length  <= be_to_unsigned(buffer_data(39 downto 8), LENGTH_BITS);
                        next_state     <= FIRST_STATE;
                    ---------------------------------------------------------------
                    -- negative fixint 111xxxxx
                    ---------------------------------------------------------------
                    else
                        unpack_code(0) <= MsgPack_Object.New_Code_Signed(
                            DATA       => be_to_signed(buffer_data(7 downto 0), 8)
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                    end if;
                -------------------------------------------------------------------
                -- Float64 Second State
                -------------------------------------------------------------------
                when FLOAT64_STATE =>
                        unpack_code(0) <= MsgPack_Object.New_Code_Float(
                            DATA       => be_to_le(buffer_data(31 downto  0)),
                            COMPLETE   => '1'
                        );
                        unpack_valid   <= to_valid(4, buffer_valid);
                        buffer_shift   <= to_shift(4);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                -------------------------------------------------------------------
                -- Unsinged Integer(64bit) Second State
                -------------------------------------------------------------------
                when UINT64_STATE =>
                        unpack_code(0) <= MsgPack_Object.New_Code_Unsigned(
                            DATA       => be_to_unsigned(buffer_data(31 downto 0), 32)
                        );
                        unpack_valid   <= to_valid(4, buffer_valid);
                        buffer_shift   <= to_shift(4);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                -------------------------------------------------------------------
                -- Signed Integer(64bit) Second State
                -------------------------------------------------------------------
                when INT64_STATE =>
                        unpack_code(0) <= MsgPack_Object.New_Code_Signed(
                            DATA       => be_to_unsigned(buffer_data(31 downto 0), 32)
                        );
                        unpack_valid   <= to_valid(4, buffer_valid);
                        buffer_shift   <= to_shift(4);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
                -------------------------------------------------------------------
                -- Ext Type State
                -------------------------------------------------------------------
                when EXT_TYPE_STATE =>
                        unpack_code(0) <= MsgPack_Object.New_Code_ExtType(
                            DATA       => buffer_data(7 downto 0),
                            COMPLETE   => data_none
                        );
                        unpack_valid   <= to_valid(1, buffer_valid);
                        buffer_shift   <= to_shift(1);
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        if (data_none = '1') then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= EXT_DATA_STATE;
                        end if;
                -------------------------------------------------------------------
                -- Ext Data State
                -------------------------------------------------------------------
                when EXT_DATA_STATE =>
                        unpack_code    <= MsgPack_Object.New_Code_Vector(
                            LENGTH     => BUFFER_WORDS,
                            CLASS      => MsgPack_Object.CLASS_EXT_DATA,
                            STRB       => data_valid,
                            DATA       => buffer_data(DECODE_BITS-1 downto 0),
                            COMPLETE   => data_none or data_last
                        );
                        unpack_valid   <= to_valid(data_valid, buffer_valid);
                        buffer_shift   <= std_logic_vector(resize(unsigned(data_valid), BUFFER_BYTES));
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        if (data_none = '1' or data_last = '1') then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= EXT_DATA_STATE;
                        end if;
                -------------------------------------------------------------------
                -- String Data State
                -------------------------------------------------------------------
                when STR_DATA_STATE =>
                        unpack_code    <= MsgPack_Object.New_Code_Vector(
                            LENGTH     => BUFFER_WORDS,
                            CLASS      => MsgPack_Object.CLASS_STRING_DATA,
                            STRB       => data_valid,
                            DATA       => buffer_data(DECODE_BITS-1 downto 0),
                            COMPLETE   => data_none or data_last
                        );
                        unpack_valid   <= to_valid(data_valid, buffer_valid);
                        buffer_shift   <= std_logic_vector(resize(unsigned(data_valid), BUFFER_BYTES));
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        if (data_none = '1' or data_last = '1') then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= STR_DATA_STATE;
                        end if;
                -------------------------------------------------------------------
                -- Binary Data State
                -------------------------------------------------------------------
                when BIN_DATA_STATE =>
                        unpack_code    <= MsgPack_Object.New_Code_Vector(
                            LENGTH     => BUFFER_WORDS,
                            CLASS      => MsgPack_Object.CLASS_BINARY_DATA,
                            STRB       => data_valid,
                            DATA       => buffer_data(DECODE_BITS-1 downto 0),
                            COMPLETE   => data_none or data_last
                        );
                        unpack_valid   <= to_valid(data_valid, buffer_valid);
                        buffer_shift   <= std_logic_vector(resize(unsigned(data_valid), BUFFER_BYTES));
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        if (data_none = '1' or data_last = '1') then
                            next_state <= FIRST_STATE;
                        else
                            next_state <= BIN_DATA_STATE;
                        end if;
                -------------------------------------------------------------------
                --
                -------------------------------------------------------------------
                when others =>
                        unpack_code    <= MsgPack_Object.New_Code_Vector(
                            LENGTH     => BUFFER_WORDS,
                            CLASS      => MsgPack_Object.CLASS_NONE,
                            STRB       => data_valid,
                            DATA       => buffer_data(DECODE_BITS-1 downto 0),
                            COMPLETE   => '1'
                        );
                        unpack_valid   <= to_valid(data_valid, buffer_valid);
                        buffer_shift   <= std_logic_vector(resize(unsigned(data_valid), BUFFER_BYTES));
                        data_length    <= dummy_data_length;
                        object_length  <= dummy_object_length;
                        next_state     <= FIRST_STATE;
            end case;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        unpack_complete <= '1' when (next_state = FIRST_STATE) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    curr_state        <= FIRST_STATE;
                    data_length_load  <= '1';
            elsif rising_edge(CLK) then
                if (CLR = '1') then
                    curr_state        <= FIRST_STATE;
                    data_length_load  <= '1';
                elsif (outlet_valid = '1' and outlet_ready = '1') then
                    curr_state        <= next_state;
                    if (next_state = FIRST_STATE) then
                        data_length_load <= '1';
                    else
                        data_length_load <= '0';
                    end if;
                end if;
            end if;
        end process;
        data_chop    <= '1' when (curr_state = STR_DATA_STATE and outlet_valid = '1' and outlet_ready = '1') or
                                 (curr_state = BIN_DATA_STATE and outlet_valid = '1' and outlet_ready = '1') or
                                 (curr_state = EXT_DATA_STATE and outlet_valid = '1' and outlet_ready = '1') else '0';
        buffer_ready <= '1' when (unpack_valid = '1' and outlet_ready = '1' and stack_ready = '1') else '0';
        outlet_valid <= '1' when (unpack_valid = '1' and stack_ready  = '1') else '0';
    end block;
    -------------------------------------------------------------------------------
    -- String/Binary/Ext Data Chopper
    -------------------------------------------------------------------------------
    CHOP: CHOPPER                                       -- 
        generic map (                                   -- 
            BURST           => 1                      , -- 
            MIN_PIECE       => DECODE_UNIT+2          , -- 
            MAX_PIECE       => DECODE_UNIT+2          , -- 
            MAX_SIZE        => LENGTH_BITS            , -- 
            ADDR_BITS       => 1                      , --
            SIZE_BITS       => LENGTH_BITS            , -- 
            COUNT_BITS      => LENGTH_BITS            , --
            PSIZE_BITS      => DECODE_UNIT+3          , -- 
            GEN_VALID       => 1                        -- 
        )                                               -- 
        port map(                                       -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                    , -- In  :
            RST             => RST                    , -- In  :
            CLR             => CLR                    , -- In  :
        ---------------------------------------------------------------------------
        -- Initialize Address and Size
        ---------------------------------------------------------------------------
            ADDR            => "0"                    , -- In  :
            SIZE            => std_logic_vector(data_length) , -- In  :
            SEL             => "1"                    , -- In  :
            LOAD            => data_length_load       , -- In  :
        ---------------------------------------------------------------------------
        -- Control Signal
        ---------------------------------------------------------------------------
            CHOP            => data_chop              , -- In  :
        ---------------------------------------------------------------------------
        -- Piece Counter and Flags
        ---------------------------------------------------------------------------
            COUNT           => open                   , -- Out :
            NONE            => data_none              , -- Out :
            LAST            => data_last              , -- Out :
            NEXT_NONE       => open                   , -- Out :
            NEXT_LAST       => open                   , -- Out :
        ---------------------------------------------------------------------------
        -- Piece Size
        ---------------------------------------------------------------------------
            PSIZE           => open                   , -- Out :
            NEXT_PSIZE      => open                   , -- Out :
        ---------------------------------------------------------------------------
        -- Piece Valid Flag
        ---------------------------------------------------------------------------
            VALID           => data_valid             , -- Out :
            NEXT_VALID      => open                     -- Out :
        );                                              -- 
    -------------------------------------------------------------------------------
    -- Array or Map Stack
    -------------------------------------------------------------------------------
    object_valid <= '1' when (unpack_valid = '1' and outlet_ready = '1') else '0';
    object_map   <= '1' when (unpack_code(0).class = MsgPack_Object.CLASS_MAP  ) else '0';
    object_array <= '1' when (unpack_code(0).class = MsgPack_Object.CLASS_ARRAY) else '0';
    STACK: MsgPack_Structure_Stack                  -- 
        generic map (                               -- 
            DEPTH           => STACK_DEPTH          -- 
        )                                           -- 
        port map (                                  -- 
            CLK             => CLK                , -- In  :
            RST             => RST                , -- In  :
            CLR             => CLR                , -- In  :
            I_VALID         => object_valid       , -- In  :
            I_SIZE          => std_logic_vector(object_length), -- In  :
            I_MAP           => object_map         , -- In  :
            I_ARRAY         => object_array       , -- In  :
            I_COMPLETE      => unpack_complete    , -- In  :
            I_READY         => stack_ready        , -- In  :
            O_LAST          => unpack_last        , -- Out :
            O_NONE          => open               , -- Out :
            O_FULL          => open                 -- 
        );                                          --
    -------------------------------------------------------------------------------
    -- Output MsgPack_Object_Code Buffer
    -------------------------------------------------------------------------------
    OUTLET: MsgPack_Object_Code_Reducer             -- 
        generic map (                               -- 
            I_WIDTH         => DECODE_WORDS       , -- 
            O_WIDTH         => CODE_WIDTH         , -- Output Object Code Width
            O_VALID_SIZE    => O_VALID_SIZE       , -- 
            QUEUE_SIZE      => 0                    -- Queue size is auto
        )                                           -- 
        port map (                                  -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                , -- In  :
            RST             => RST                , -- In  :
            CLR             => CLR                , -- In  :
        ---------------------------------------------------------------------------
        -- Control and Status Signals
        ---------------------------------------------------------------------------
            DONE            => '0'                , -- In  :
            BUSY            => open               , -- Out :
        ---------------------------------------------------------------------------
        -- Object Code Input Interface
        ---------------------------------------------------------------------------
            I_ENABLE        => '1'                , -- In  :
            I_CODE          => unpack_code(DECODE_WORDS-1 downto 0), -- In  :
            I_DONE          => unpack_last        , -- In  :
            I_VALID         => outlet_valid       , -- In  :
            I_READY         => outlet_ready       , -- Out :
        ---------------------------------------------------------------------------
        -- Object Code Output Interface
        ---------------------------------------------------------------------------
            O_ENABLE        => '1'                , -- In  :
            O_CODE          => O_CODE             , -- Out :
            O_DONE          => O_LAST             , -- Out :
            O_VALID         => O_VALID            , -- Out :
            O_READY         => O_READY            , -- In  :
            O_SHIFT         => O_SHIFT              -- In  :
    );                                              -- 
end RTL;
