-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_binary_stream.vhd
--!     @brief   MessagePack Object Encode to Binary/String Stream
--!     @version 0.2.0
--!     @date    2016/6/8
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
entity  MsgPack_Object_Encode_Binary_Stream is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 32;
        SIZE_BITS       :  positive := 32;
        ENCODE_BINARY   :  boolean  := TRUE;
        ENCODE_STRING   :  boolean  := FALSE;
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
    -- Binary/String Data Stream Input Interface
    -------------------------------------------------------------------------------
        I_START         : out std_logic;
        I_BUSY          : out std_logic;
        I_DATA          : in  std_logic_vector(DATA_BITS  -1 downto 0);
        I_STRB          : in  std_logic_vector(DATA_BITS/8-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic
    );
end MsgPack_Object_Encode_Binary_Stream;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.PipeWork_Components.REDUCER;
architecture RTL of MsgPack_Object_Encode_Binary_Stream is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  CODE_DATA_BITS    :  integer := MsgPack_Object.CODE_DATA_BITS;
    constant  CODE_STRB_BITS    :  integer := MsgPack_Object.CODE_STRB_BITS;
    constant  CODE_STRB_NULL    :  std_logic_vector(CODE_STRB_BITS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  CODE_BITS         :  integer := CODE_WIDTH*CODE_DATA_BITS;
    constant  CODE_BYTES        :  integer := CODE_BITS/8;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_enable     :  std_logic;
    signal    intake_data       :  std_logic_vector(CODE_BITS -1 downto 0);
    signal    intake_strb       :  std_logic_vector(CODE_BYTES-1 downto 0);
    signal    intake_last       :  std_logic;
    signal    intake_valid      :  std_logic;
    signal    intake_ready      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    outlet_code       :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    outlet_last       :  std_logic;
    signal    outlet_valid      :  std_logic;
    signal    outlet_ready      :  std_logic;
    signal    outlet_busy       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE       is (IDLE_STATE, SIZE_STATE, DATA_STATE);
    signal    curr_state        :  STATE_TYPE;
    signal    curr_size         :  unsigned(SIZE'length-1 downto 0);
    signal    size_zero         :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    INTAKE_BUFFERED: if (I_BUFFERED = TRUE or I_JUSTIFIED  = FALSE or  CODE_BITS /= DATA_BITS) generate
        function  to_integer(ARG:boolean) return integer is begin
            if (ARG) then return 1;
            else          return 0;
            end if;
        end function;
        constant  offeset      :  std_logic_vector(CODE_BYTES-1 downto 0) := (others => '0');
    begin
        BUF: REDUCER                                    -- 
            generic map (                               -- 
                WORD_BITS       => 8                  , -- 1 byte(8bit)
                STRB_BITS       => 1                  , -- 1 bit
                I_WIDTH         => DATA_BITS/8        , -- Input Byte Size
                O_WIDTH         => CODE_BYTES         , -- Output Byte Size
                QUEUE_SIZE      => 0                  , -- Queue depth auto
                VALID_MIN       => 0                  , -- VALID unused
                VALID_MAX       => 0                  , -- VALID unused
                O_VAL_SIZE      => CODE_BYTES         , -- 
                O_SHIFT_MIN     => CODE_BYTES         , -- SHIFT unused
                O_SHIFT_MAX     => CODE_BYTES         , -- SHIFT unused
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
                BUSY            => open               , -- Out :
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
                I_RDY           => I_READY            , -- Out :
            -----------------------------------------------------------------------
            -- Byte Stream Output Interface
            -----------------------------------------------------------------------
                O_ENABLE        => '1'                , -- In  :
                O_DATA          => intake_data        , -- Out :
                O_STRB          => intake_strb        , -- Out :
                O_DONE          => intake_last        , -- Out :
                O_FLUSH         => open               , -- Out :
                O_VAL           => intake_valid       , -- Out :
                O_RDY           => intake_ready       , -- In  :
                O_SHIFT         => "0"                  -- In  :
        );                                              --
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    INTAKE_THROUGH : if (I_BUFFERED = FALSE and I_JUSTIFIED = TRUE and CODE_BITS = DATA_BITS) generate
    begin
        intake_data  <= I_DATA;
        intake_strb  <= I_STRB;
        intake_last  <= I_LAST;
        intake_valid <= I_VALID;
        I_READY      <= intake_ready;
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_state, curr_size, size_zero, intake_valid, intake_data, intake_strb, intake_last)
        variable  complete  :  std_logic;
    begin
        case curr_state is
            when SIZE_STATE =>
                if (ENCODE_STRING) then
                    outlet_code <= MsgPack_Object.New_Code_Vector_StringSize(CODE_WIDTH, curr_size, size_zero);
                else
                    outlet_code <= MsgPack_Object.New_Code_Vector_BinarySize(CODE_WIDTH, curr_size, size_zero);
                end if;
                outlet_valid <= '1';
                outlet_last  <= size_zero;
            when others =>
                complete := intake_last;
                for i in CODE_WIDTH-1 downto 0 loop
                    if (ENCODE_STRING) then
                        outlet_code(i).class <= MsgPack_Object.CLASS_STRING_DATA;
                    else
                        outlet_code(i).class <= MsgPack_Object.CLASS_BINARY_DATA;
                    end if;
                    outlet_code(i).data <= intake_data(CODE_DATA_BITS*(i+1)-1 downto CODE_DATA_BITS*i);
                    outlet_code(i).strb <= intake_strb(CODE_STRB_BITS*(i+1)-1 downto CODE_STRB_BITS*i);
                    if (intake_strb(CODE_STRB_BITS*(i+1)-1 downto CODE_STRB_BITS*i) /= CODE_STRB_NULL) then
                        outlet_code(i).valid    <= '1';
                        outlet_code(i).complete <= complete;
                        complete := '0';
                    else
                        outlet_code(i).valid    <= '0';
                        outlet_code(i).complete <= '0';
                    end if;
                end loop;
                outlet_valid <= intake_valid;
                outlet_last  <= intake_last;
        end case;
    end process;
    intake_ready <= outlet_ready;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
                curr_size  <= (others => '0');
                size_zero  <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
                curr_size  <= (others => '0');
                size_zero  <= '0';
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (START = '1') then
                            curr_state <= SIZE_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                        curr_size  <= unsigned(SIZE);
                        if (unsigned(SIZE) = 0) then
                            size_zero <= '1';
                        else
                            size_zero <= '0';
                        end if;
                    when SIZE_STATE =>
                        if    (outlet_ready = '0') then
                            curr_state <= SIZE_STATE;
                        elsif (outlet_last  = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= DATA_STATE;
                        end if;
                    when DATA_STATE =>
                        if (outlet_valid = '1' and outlet_ready = '1' and outlet_last = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= DATA_STATE;
                        end if;
                    when others =>
                        curr_state <= IDLE_STATE;
                end case;
            end if;
        end if;
    end process;
    BUSY          <= '1' when (curr_state /= IDLE_STATE) else '0';
    intake_enable <= '1' when (curr_state  = SIZE_STATE and size_zero  = '0') or
                              (curr_state  = DATA_STATE                     ) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    outlet_ready  <= O_READY;
    O_CODE        <= outlet_code;
    O_LAST        <= outlet_last;
    O_VALID       <= outlet_valid;
    O_ERROR       <= '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    I_START       <= '1' when (curr_state = SIZE_STATE and outlet_ready = '1' and size_zero = '0') else '0';
    I_BUSY        <= '1' when (curr_state = DATA_STATE) else '0';
end RTL;
