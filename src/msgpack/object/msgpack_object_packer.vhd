-----------------------------------------------------------------------------------
--!     @file    msgpack_object_packer.vhd
--!     @brief   MessagePack Object Code Pack to Byte Stream Module :
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
entity  MsgPack_Object_Packer is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      : positive := 1;
        O_BYTES         : positive := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_SHIFT         : out std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Byte Stream Output Interface
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(           8*O_BYTES-1 downto 0);
        O_STRB          : out std_logic_vector(             O_BYTES-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end MsgPack_Object_Packer;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.PipeWork_Components.REDUCER;
architecture RTL of MsgPack_Object_Packer is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   max(A,B:integer) return integer is begin
        if (A > B) then return A;
        else            return B;
        end if;
    end function;
    constant   BUFFER_WORDS      :  integer := max(3, CODE_WIDTH);
    constant   BUFFER_BYTES      :  integer := BUFFER_WORDS*4+1;
    signal     intake_code       :  MsgPack_Object.Code_Vector(BUFFER_WORDS-1 downto 0);
    signal     intake_valid      :  std_logic_vector       (BUFFER_WORDS-1 downto 0);
    signal     intake_shift      :  std_logic_vector       (BUFFER_WORDS-1 downto 0);
    signal     intake_last       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant   ENCODE_WIDTH      :  integer := CODE_WIDTH;
    constant   ENCODE_BYTES      :  integer := CODE_WIDTH*4;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant   OUTLET_BYTES      :  integer := ENCODE_BYTES+1;
    constant   outlet_offset     :  std_logic_vector(       O_BYTES-1 downto 0) := (others => '0');
    signal     outlet_strb       :  std_logic_vector(  BUFFER_BYTES-1 downto 0);
    signal     outlet_data       :  std_logic_vector(8*BUFFER_BYTES-1 downto 0);
    signal     outlet_last       :  std_logic;
    signal     outlet_valid      :  std_logic;
    signal     outlet_ready      :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    INTAKE: block
    begin
        process (I_CODE) begin
            for i in 0 to BUFFER_WORDS-1 loop
                if (i < CODE_WIDTH) then
                    intake_code (i) <= I_CODE(i);
                    intake_valid(i) <= I_CODE(i).valid;
                else
                    intake_code (i) <= MsgPack_Object.CODE_NULL;
                    intake_valid(i) <= '0';
                end if;
            end loop;
        end process;
        I_SHIFT     <= intake_shift(CODE_WIDTH-1 downto 0);
        intake_last <= I_LAST;
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ENCODE: block
        type      STATE_TYPE  is(FIRST_STATE,
                                 ERROR_STATE,
                                 UINT64_STATE,
                                 INT64_STATE,
                                 FLOAT64_STATE,
                                 STR_DATA_STATE,
                                 BIN_DATA_STATE,
                                 EXT_DATA_STATE,
                                 EXT_TYPE_NONE_DATA_STATE,
                                 EXT_TYPE_WITH_DATA_STATE);
        signal    next_state  :  STATE_TYPE;
        signal    curr_state  :  STATE_TYPE;
    begin
        process (curr_state, intake_code, intake_last, intake_valid, outlet_ready)
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            type      ENCODE_TYPE     is record
                          data    :  std_logic_vector(8*BUFFER_BYTES-1 downto 0);
                          strb    :  std_logic_vector(  BUFFER_BYTES-1 downto 0);
                          valid   :  std_logic;
                          last    :  std_logic;
                          shift   :  std_logic_vector(  BUFFER_WORDS-1 downto 0);
            end record;
            constant  ENC_NULL    :  ENCODE_TYPE := (
                          data    => (others => '0'),
                          strb    => (others => '0'),
                          valid   => '0',
                          last    => '0',
                          shift   => (others => '0'));
            variable  enc         :  ENCODE_TYPE;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            function  to_enc_strb(size: integer) return std_logic_vector is
                variable strb  : std_logic_vector(BUFFER_BYTES-1 downto 0);
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
            function  to_enc_shift(size: integer) return std_logic_vector is
                variable ready : std_logic_vector(BUFFER_WORDS-1 downto 0);
            begin
                for i in ready'range loop
                    if (i < size) then
                        ready(i) := '1';
                    else
                        ready(i) := '0';
                    end if;
                end loop;
                return ready;
            end function;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            function to_enc_last(shift,valid: std_logic_vector;last:std_logic) return std_logic is
                constant all_0 : std_logic_vector(BUFFER_WORDS-1 downto 0) := (others => '0');
            begin 
                if (last = '1' and ((valid and not shift) = all_0)) then
                    return '1';
                else
                    return '0';
                end if;
            end function;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            procedure set_enc is
            begin
                enc.data := std_logic_vector(to_unsigned(0, 8*BUFFER_BYTES));
                enc.strb := to_enc_strb(0);
                if (intake_valid(0) = '1') then
                    enc.valid := '1';
                    enc.shift := to_enc_shift(1);
                else
                    enc.valid := '0';
                    enc.shift := to_enc_shift(0);
                end if;
                enc.last := to_enc_last(enc.shift, intake_valid, intake_last);
            end procedure;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            procedure set_enc(code: in integer range 0 to 255) is
            begin
                enc.data := std_logic_vector(to_unsigned(code, 8*BUFFER_BYTES));
                enc.strb := to_enc_strb(1);
                if (intake_valid(0) = '1') then
                    enc.valid := '1';
                    enc.shift := to_enc_shift(1);
                else
                    enc.valid := '0';
                    enc.shift := to_enc_shift(0);
                end if;
                enc.last := to_enc_last(enc.shift, intake_valid, intake_last);
            end procedure;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            procedure set_enc(code: in integer range 0 to 255; I0:std_logic_vector) is
            begin
                enc.data( 7 downto  0) := std_logic_vector(to_unsigned(code, 8));
                enc.data(15 downto  8) := I0;
                enc.data(enc.data'high downto 16) := (enc.data'high downto 16 => '0');
                enc.strb := to_enc_strb(2);
                if (intake_valid(0) = '1') then
                    enc.valid := '1';
                    enc.shift := to_enc_shift(1);
                else
                    enc.valid := '0';
                    enc.shift := to_enc_shift(0);
                end if;
                enc.last := to_enc_last(enc.shift, intake_valid, intake_last);
            end procedure;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            procedure set_enc(code: in integer range 0 to 255; I0,I1:std_logic_vector) is
            begin
                enc.data( 7 downto  0) := std_logic_vector(to_unsigned(code, 8));
                enc.data(15 downto  8) := I0;
                enc.data(23 downto 16) := I1;
                enc.data(enc.data'high downto 24) := (enc.data'high downto 24 => '0');
                enc.strb := to_enc_strb(3);
                if (intake_valid(0) = '1') then
                    enc.valid := '1';
                    enc.shift := to_enc_shift(1);
                else
                    enc.valid := '0';
                    enc.shift := to_enc_shift(0);
                end if;
                enc.last := to_enc_last(enc.shift, intake_valid, intake_last);
            end procedure;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            procedure set_enc(code: in integer range 0 to 255; I0,I1,I2,I3:std_logic_vector) is
            begin
                enc.data( 7 downto  0) := std_logic_vector(to_unsigned(code, 8));
                enc.data(15 downto  8) := I0;
                enc.data(23 downto 16) := I1;
                enc.data(31 downto 24) := I2;
                enc.data(39 downto 32) := I3;
                enc.data(enc.data'high downto 40) := (enc.data'high downto 40 => '0');
                enc.strb := to_enc_strb(5);
                if (intake_valid(0) = '1') then
                    enc.valid := '1';
                    enc.shift := to_enc_shift(1);
                else
                    enc.valid := '0';
                    enc.shift := to_enc_shift(0);
                end if;
                enc.last := to_enc_last(enc.shift, intake_valid, intake_last);
            end procedure;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            procedure set_enc(code: in integer range 0 to 255; I0,I1,I2,I3,I4,I5,I6,I7:std_logic_vector) is
            begin
                enc.data( 7 downto  0) := std_logic_vector(to_unsigned(code, 8));
                enc.data(15 downto  8) := I0;
                enc.data(23 downto 16) := I1;
                enc.data(31 downto 24) := I2;
                enc.data(39 downto 32) := I3;
                enc.data(47 downto 40) := I4;
                enc.data(55 downto 48) := I5;
                enc.data(63 downto 56) := I6;
                enc.data(71 downto 64) := I7;
                enc.data(enc.data'high downto 73) := (enc.data'high downto 73 => '0');
                enc.strb := to_enc_strb(9);
                if (intake_valid(0) = '1' and intake_valid(1) = '1') then
                    enc.valid := '1';
                    enc.shift := to_enc_shift(2);
                else
                    enc.valid := '0';
                    enc.shift := to_enc_shift(0);
                end if;
                enc.last := to_enc_last(enc.shift, intake_valid, intake_last);
            end procedure;
            -----------------------------------------------------------------------
            -- 
            -----------------------------------------------------------------------
            procedure set_enc(I0,I1,I2,I3:std_logic_vector) is
            begin
                enc.data( 7 downto  0) := I0;
                enc.data(15 downto  8) := I1;
                enc.data(23 downto 16) := I2;
                enc.data(31 downto 24) := I3;
                enc.data(enc.data'high downto 32) := (enc.data'high downto 32 => '0');
                enc.strb := to_enc_strb(4);
                if (intake_valid(0) = '1') then
                    enc.valid := '1';
                    enc.shift := to_enc_shift(1);
                else
                    enc.valid := '0';
                    enc.shift := to_enc_shift(0);
                end if;
                enc.last := to_enc_last(enc.shift, intake_valid, intake_last);
            end procedure;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            variable  obj_size  :  unsigned(31 downto 0);
            variable  byte_code :  integer range 0 to 255;
            variable  complete  :  boolean;
            variable  valid     :  std_logic;
        begin
            case curr_state is
                when FIRST_STATE =>
                    case intake_code(0).class is
                        -----------------------------------------------------------
                        -- None or Reserve
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_NONE    |
                             MsgPack_Object.CLASS_RESERVE =>
                            set_enc;
                            next_state <= FIRST_STATE;
                        -----------------------------------------------------------
                        -- Nil format
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_NIL =>
                            set_enc(16#C0#);
                            next_state <= FIRST_STATE;
                        -----------------------------------------------------------
                        -- Boolean format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_BOOLEAN =>
                            if (intake_code(0).DATA(0) = '1') then
                                set_enc(16#C3#);
                            else
                                set_enc(16#C2#);
                            end if;
                            next_state <= FIRST_STATE;
                        -----------------------------------------------------------
                        -- Array format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_ARRAY =>
                            obj_size := unsigned(intake_code(0).DATA);
                            if    (obj_size < 16) then
                                byte_code := 16#90# + to_integer(to_01(unsigned(intake_code(0).DATA(3 downto 0))));
                                set_enc(byte_code);
                                next_state <= FIRST_STATE;
                            elsif (obj_size < 16#10000#) then
                                set_enc(16#DC#,
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            else
                                set_enc(16#DD#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            end if;
                        -----------------------------------------------------------
                        -- Map format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_MAP =>
                            obj_size := unsigned(intake_code(0).DATA);
                            if    (obj_size < 16) then
                                byte_code := 16#80# + to_integer(to_01(unsigned(intake_code(0).DATA(3 downto 0))));
                                set_enc(byte_code);
                                next_state <= FIRST_STATE;
                            elsif (obj_size < 16#10000#) then
                                set_enc(16#DE#,
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            else
                                set_enc(16#DF#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            end if;
                        -----------------------------------------------------------
                        -- Unsigned Integer format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_UINT =>
                            if    (intake_code(0).complete = '0' and ENCODE_WIDTH >= 2) then
                                set_enc(16#CF#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0),
                                        intake_code(1).DATA(31 downto 24),
                                        intake_code(1).DATA(23 downto 16),
                                        intake_code(1).DATA(15 downto  8),
                                        intake_code(1).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            elsif (intake_code(0).complete = '0' and ENCODE_WIDTH <  2) then
                                set_enc(16#CF#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                if (enc.valid = '1' and outlet_ready = '1') then
                                    next_state <= UINT64_STATE;
                                else
                                    next_state <= FIRST_STATE;
                                end if;
                            elsif (unsigned(intake_code(0).DATA) < 16#80#) then
                                set_enc(to_integer(unsigned(intake_code(0).DATA(6 downto 0))));
                                next_state <= FIRST_STATE;
                            elsif (unsigned(intake_code(0).DATA) < 16#100#) then
                                set_enc(16#CC#,
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            elsif (unsigned(intake_code(0).DATA) < 16#10000#) then
                                set_enc(16#CD#,
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            else
                                set_enc(16#CE#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            end if;
                        -----------------------------------------------------------
                        -- Signed Integer format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_INT =>
                            if    (intake_code(0).complete = '0' and ENCODE_WIDTH >= 2) then
                                set_enc(16#D3#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0),
                                        intake_code(1).DATA(31 downto 24),
                                        intake_code(1).DATA(23 downto 16),
                                        intake_code(1).DATA(15 downto  8),
                                        intake_code(1).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            elsif (intake_code(0).complete = '0' and ENCODE_WIDTH <  2) then
                                set_enc(16#D3#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                if (enc.valid = '1' and outlet_ready = '1') then
                                    next_state <= INT64_STATE;
                                else
                                    next_state <= FIRST_STATE;
                                end if;
                            elsif (signed(intake_code(0).DATA) >= -32) and
                                  (signed(intake_code(0).DATA) <= 127) then
                                set_enc(to_integer(unsigned(intake_code(0).DATA(7 downto 0))));
                                next_state <= FIRST_STATE;
                            elsif (signed(intake_code(0).DATA) >= -128) and
                                  (signed(intake_code(0).DATA) <=  127) then
                                set_enc(16#D0#,
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            elsif (signed(intake_code(0).DATA) >= -32768) and
                                  (signed(intake_code(0).DATA) <=  32767) then
                                set_enc(16#D1#,
                                        intake_code(0).DATA( 15 downto  8),
                                        intake_code(0).DATA(  7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            else
                                set_enc(16#D2#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            end if;
                        -----------------------------------------------------------
                        -- Float format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_FLOAT =>
                            if    (intake_code(0).complete = '0' and ENCODE_WIDTH >= 2) then
                                set_enc(16#CB#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0),
                                        intake_code(1).DATA(31 downto 24),
                                        intake_code(1).DATA(23 downto 16),
                                        intake_code(1).DATA(15 downto  8),
                                        intake_code(1).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            elsif (intake_code(0).complete = '0' and ENCODE_WIDTH <  2) then
                                set_enc(16#CB#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                if (enc.valid = '1' and outlet_ready = '1') then
                                    next_state <= FLOAT64_STATE;
                                else
                                    next_state <= FIRST_STATE;
                                end if;
                            else
                                set_enc(16#CA#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                                next_state <= FIRST_STATE;
                            end if;
                        -----------------------------------------------------------
                        -- String format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_STRING_SIZE =>
                            obj_size := unsigned(intake_code(0).DATA);
                            if    (obj_size < 32) then
                                byte_code := 16#A0# + to_integer(to_01(unsigned(intake_code(0).DATA(4 downto 0))));
                                set_enc(byte_code);
                            elsif (obj_size < 16#100#) then
                                set_enc(16#D9#,
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            elsif (obj_size < 16#10000#) then
                                set_enc(16#DA#,
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            else
                                set_enc(16#DB#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            end if;
                            if (enc.valid = '1' and outlet_ready = '1' and obj_size > 0) then
                                next_state <= STR_DATA_STATE;
                            else
                                next_state <= FIRST_STATE;
                            end if;
                        -----------------------------------------------------------
                        -- Binary format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_BINARY_SIZE =>
                            obj_size := unsigned(intake_code(0).DATA);
                            if    (obj_size < 16#100#) then
                                set_enc(16#C4#,
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            elsif (obj_size < 16#10000#) then
                                set_enc(16#C5#,
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            else
                                set_enc(16#C6#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            end if;
                            if (enc.valid = '1' and outlet_ready = '1' and obj_size > 0) then
                                next_state <= BIN_DATA_STATE;
                            else
                                next_state <= FIRST_STATE;
                            end if;
                        -----------------------------------------------------------
                        -- Ext format family
                        -----------------------------------------------------------
                        when MsgPack_Object.CLASS_EXT_SIZE =>
                            obj_size := unsigned(intake_code(0).DATA);
                            if    (obj_size = 1) then
                                set_enc(16#D4#);
                            elsif (obj_size = 2) then
                                set_enc(16#D5#);
                            elsif (obj_size = 4) then
                                set_enc(16#D6#);
                            elsif (obj_size = 8) then
                                set_enc(16#D7#);
                            elsif (obj_size = 16) then
                                set_enc(16#D8#);
                            elsif (obj_size < 16#100#) then
                                set_enc(16#C7#,
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            elsif (obj_size < 16#10000#) then
                                set_enc(16#C8#,
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            else
                                set_enc(16#C9#,
                                        intake_code(0).DATA(31 downto 24),
                                        intake_code(0).DATA(23 downto 16),
                                        intake_code(0).DATA(15 downto  8),
                                        intake_code(0).DATA( 7 downto  0)
                                );
                            end if;
                            if (enc.valid = '1' and outlet_ready = '1') then
                                if (obj_size > 0) then
                                    next_state <= EXT_TYPE_WITH_DATA_STATE;
                                else
                                    next_state <= EXT_TYPE_NONE_DATA_STATE;
                                end if;
                            else
                                    next_state <= FIRST_STATE;
                            end if;
                        -----------------------------------------------------------
                        -- Format Error 
                        -----------------------------------------------------------
                        when others =>
                            set_enc(0);
                            if (enc.valid = '1' and outlet_ready = '1') then
                                next_state <= ERROR_STATE;
                            else
                                next_state <= FIRST_STATE;
                            end if;
                    end case;
                -------------------------------------------------------------------
                -- UINT64/INT64/FLOAT64
                -------------------------------------------------------------------
                when UINT64_STATE | INT64_STATE | FLOAT64_STATE =>
                    set_enc(
                        intake_code(0).DATA(31 downto 24),
                        intake_code(0).DATA(23 downto 16),
                        intake_code(0).DATA(15 downto  8),
                        intake_code(0).DATA( 7 downto  0)
                    );
                    if (enc.valid = '1' and outlet_ready = '1') then
                        next_state <= FIRST_STATE;
                    else
                        next_state <= curr_state;
                    end if;
                -------------------------------------------------------------------
                -- Ext type 
                -------------------------------------------------------------------
                when EXT_TYPE_WITH_DATA_STATE | EXT_TYPE_NONE_DATA_STATE =>
                    byte_code := to_integer(unsigned(intake_code(0).DATA(7 downto 0)));
                    set_enc(byte_code);
                    if (enc.valid = '1' and outlet_ready = '1' and curr_state = EXT_TYPE_WITH_DATA_STATE) then
                        next_state <= EXT_DATA_STATE;
                    else
                        next_state <= FIRST_STATE;
                    end if;
                -------------------------------------------------------------------
                -- String/Binary/Ext data 
                -------------------------------------------------------------------
                when STR_DATA_STATE | BIN_DATA_STATE | EXT_DATA_STATE =>
                    complete  := FALSE;
                    enc.valid := '0';
                    for i in 0 to BUFFER_WORDS-1 loop
                        enc.data(32*(i+1)-1 downto 32*i) := intake_code(i).DATA;
                        if (complete = FALSE and intake_valid(i) = '1') then
                            enc.strb(4*(i+1)-1 downto 4*i) := intake_code(i).STRB;
                            enc.shift(i) := '1';
                            enc.valid := '1';
                            if (intake_code(i).complete = '1') then
                                complete := TRUE;
                            end if;
                        else
                            enc.strb(4*i+3 downto 4*i) := "0000";
                            enc.shift(i) := '0';
                        end if;
                    end loop;
                    if (complete and enc.valid = '1' and outlet_ready = '1') then
                        next_state <= FIRST_STATE;
                    else
                        next_state <= curr_state;
                    end if;
                    enc.last := to_enc_last(enc.shift, intake_valid, intake_last);
                -------------------------------------------------------------------
                -- Error State
                -------------------------------------------------------------------
                when others =>
                    enc := ENC_NULL;
                    next_state <= ERROR_STATE;
            end case;
            outlet_data  <= enc.data;
            outlet_strb  <= enc.strb;
            outlet_last  <= enc.last;
            outlet_valid <= enc.valid;
            if (outlet_ready = '1') then
                intake_shift <= enc.shift;
            else
                intake_shift <= (others => '0');
            end if;
        end process;
        process(CLK, RST) begin
            if (RST = '1') then
                    curr_state <= FIRST_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    curr_state <= FIRST_STATE;
                else
                    curr_state <= next_state;
                end if;
            end if;
        end process;
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    OUTLET: REDUCER                                 -- 
        generic map (                               -- 
            WORD_BITS       => 8                  , -- 1 byte(8bit)
            STRB_BITS       => 1                  , -- 1 bit
            I_WIDTH         => OUTLET_BYTES       , -- 
            O_WIDTH         => O_BYTES            , -- Output Byte Size
            QUEUE_SIZE      => 0                  , -- Queue size is auto
            VALID_MIN       => 0                  , -- VALID unused
            VALID_MAX       => 0                  , -- VALID unused
            O_VAL_SIZE      => O_BYTES+1          , -- 
            O_SHIFT_MIN     => O_BYTES            , -- SHIFT unused
            O_SHIFT_MAX     => O_BYTES            , -- SHIFT unused
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
            OFFSET          => outlet_offset      , -- In  :
            DONE            => '0'                , -- In  :
            FLUSH           => '0'                , -- In  :
            BUSY            => open               , -- Out :
            VALID           => open               , -- Out :
        ---------------------------------------------------------------------------
        -- Byte Stream Input Interface
        ---------------------------------------------------------------------------
            I_ENABLE        => '1'                , -- In  :
            I_STRB          => outlet_strb(  OUTLET_BYTES-1 downto 0), -- In  :
            I_DATA          => outlet_data(8*OUTLET_BYTES-1 downto 0), -- In  :
            I_DONE          => outlet_last        , -- In  :
            I_FLUSH         => '0'                , -- In  :
            I_VAL           => outlet_valid       , -- In  :
            I_RDY           => outlet_ready       , -- Out :
        ---------------------------------------------------------------------------
        -- Byte Stream Output Interface
        ---------------------------------------------------------------------------
            O_ENABLE        => '1'                , -- In  :
            O_DATA          => O_DATA             , -- Out :
            O_STRB          => O_STRB             , -- Out :
            O_DONE          => O_LAST             , -- Out :
            O_FLUSH         => open               , -- Out :
            O_VAL           => O_VALID            , -- Out :
            O_RDY           => O_READY            , -- In  :
            O_SHIFT         => "0"                  -- In  :
    );                                              --
end RTL;
