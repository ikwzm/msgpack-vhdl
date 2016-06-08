-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_binary_array.vhd
--!     @brief   MessagePack Object Decode to Binary/String Array
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
entity  MsgPack_Object_Decode_Binary_Array is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 4;
        ADDR_BITS       :  integer  := 8;
        DECODE_BINARY   :  boolean  := TRUE;
        DECODE_STRING   :  boolean  := FALSE
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
        I_ADDR          : in  std_logic_vector(ADDR_BITS  -1 downto 0);
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH -1 downto 0);
    -------------------------------------------------------------------------------
    -- Binary/String Data Output Interface
    -------------------------------------------------------------------------------
        O_START         : out std_logic;
        O_BUSY          : out std_logic;
        O_ADDR          : out std_logic_vector(ADDR_BITS  -1 downto 0);
        O_DATA          : out std_logic_vector(DATA_BITS  -1 downto 0);
        O_STRB          : out std_logic_vector(DATA_BITS/8-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end  MsgPack_Object_Decode_Binary_Array;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Binary_Core;
use     MsgPack.PipeWork_Components.REDUCER;
use     MsgPack.PipeWork_Components.CHOPPER;
architecture RTL of MsgPack_Object_Decode_Binary_Array is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function calc_width(BYTES:integer) return integer is
        variable width : integer;
    begin
        width := 0;
        while (2**width < BYTES) loop
            width := width + 1;
        end loop;
        return width;
    end function;
    constant  OUTLET_BYTES      :  integer := DATA_BITS/8;
    constant  OUTLET_WIDTH      :  integer := calc_width(OUTLET_BYTES);
    signal    outlet_valid      :  std_logic;
    signal    outlet_strb       :  std_logic_vector(OUTLET_BYTES-1 downto 0);
    signal    outlet_offset     :  std_logic_vector(OUTLET_BYTES-1 downto 0);
    signal    outlet_size       :  integer range 0 to OUTLET_BYTES;
    signal    outlet_start      :  std_logic;
    signal    outlet_busy       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  INTAKE_BITS       :  integer := CODE_WIDTH * MsgPack_Object.CODE_DATA_BITS;
    constant  INTAKE_BYTES      :  integer := CODE_WIDTH * MsgPack_Object.CODE_DATA_BYTES;
    signal    intake_enable     :  std_logic;
    signal    intake_start      :  std_logic;
    signal    intake_busy       :  std_logic;
    signal    intake_valid      :  std_logic;
    signal    intake_last       :  std_logic;
    signal    intake_ready      :  std_logic;
    signal    intake_strb       :  std_logic_vector(INTAKE_BYTES-1 downto 0);
    signal    intake_data       :  std_logic_vector(INTAKE_BITS -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    curr_addr         :  std_logic_vector(ADDR_BITS   -1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    CORE: MsgPack_Object_Decode_Binary_Core        -- 
        generic map (                              -- 
            CODE_WIDTH      => CODE_WIDTH        , --
            DECODE_BINARY   => DECODE_BINARY     , --
            DECODE_STRING   => DECODE_STRING       --
        )                                          -- 
        port map (                                 -- 
            CLK             => CLK               , -- In  :
            RST             => RST               , -- In  :
            CLR             => CLR               , -- In  :
            I_CODE          => I_CODE            , -- In  :
            I_LAST          => I_LAST            , -- In  :
            I_VALID         => I_VALID           , -- In  :
            I_ERROR         => I_ERROR           , -- Out :
            I_DONE          => I_DONE            , -- Out :
            I_SHIFT         => I_SHIFT           , -- Out :
            O_ENABLE        => intake_enable     , -- Out :
            O_START         => intake_start      , -- Out :
            O_BUSY          => intake_busy       , -- Out :
            O_SIZE          => open              , -- Out :
            O_DATA          => intake_data       , -- Out :
            O_STRB          => intake_strb       , -- Out :
            O_LAST          => intake_last       , -- Out :
            O_VALID         => intake_valid      , -- Out :
            O_READY         => intake_ready        -- In  :
        );                                         -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    OUTLET_BYTES_1: if (OUTLET_BYTES = 1) generate
        O_START       <= intake_start;
        outlet_start  <= '0';
        outlet_offset <= (others => '0');
        outlet_size   <= 1;
    end generate;
    OUTLET_BYTES_2: if (OUTLET_BYTES > 1) generate
        O_START       <= intake_start;
        outlet_start  <= intake_start;
        ---------------------------------------------------------------------------
        -- outlet_offset
        ---------------------------------------------------------------------------
        process (I_ADDR)
            variable offset_addr :  unsigned(OUTLET_WIDTH-1 downto 0);
        begin
            offset_addr := to_01(unsigned(I_ADDR(offset_addr'range)));
            for i in outlet_offset'range loop
                if (i < offset_addr) then
                    outlet_offset(i) <= '1';
                else
                    outlet_offset(i) <= '0';
                end if;
            end loop;
        end process;
        ---------------------------------------------------------------------------
        -- outlet_size
        ---------------------------------------------------------------------------
        process (outlet_strb)
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
            variable size : integer range 0 to outlet_strb'length;
        begin
            outlet_size <= count_assert_bit(outlet_strb);
        end process;
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    QUEUE: REDUCER                                  -- 
        generic map (                               -- 
            WORD_BITS       => 8                  , -- 1 byte(8bit)
            STRB_BITS       => 1                  , -- 1 bit
            I_WIDTH         => INTAKE_BYTES       , -- 
            O_WIDTH         => OUTLET_BYTES       , -- Output Byte Size
            QUEUE_SIZE      => 0                  , -- Queue size is auto
            VALID_MIN       => 0                  , -- VALID unused
            VALID_MAX       => 0                  , -- VALID unused
            O_VAL_SIZE      => OUTLET_BYTES       , -- 
            O_SHIFT_MIN     => OUTLET_BYTES       , -- SHIFT unused
            O_SHIFT_MAX     => OUTLET_BYTES       , -- SHIFT unused
            I_JUSTIFIED     => 0                  , -- 
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
            START           => outlet_start       , -- In  :
            OFFSET          => outlet_offset      , -- In  :
            DONE            => '0'                , -- In  :
            FLUSH           => '0'                , -- In  :
            BUSY            => outlet_busy        , -- Out :
            VALID           => open               , -- Out :
        ---------------------------------------------------------------------------
        -- Byte Stream Input Interface
        ---------------------------------------------------------------------------
            I_ENABLE        => intake_enable      , -- In  :
            I_STRB          => intake_strb        , -- In  :
            I_DATA          => intake_data        , -- In  :
            I_DONE          => intake_last        , -- In  :
            I_FLUSH         => '0'                , -- In  :
            I_VAL           => intake_valid       , -- In  :
            I_RDY           => intake_ready       , -- Out :
        ---------------------------------------------------------------------------
        -- Byte Stream Output Interface
        ---------------------------------------------------------------------------
            O_ENABLE        => '1'                , -- In  :
            O_DATA          => O_DATA             , -- Out :
            O_STRB          => outlet_strb        , -- Out :
            O_DONE          => O_LAST             , -- Out :
            O_FLUSH         => open               , -- Out :
            O_VAL           => outlet_valid       , -- Out :
            O_RDY           => O_READY            , -- In  :
            O_SHIFT         => "0"                  -- In  :
    );                                              --
    O_VALID <= outlet_valid;                        --
    O_STRB  <= outlet_strb;                         --
    O_ADDR  <= curr_addr;                           --
    O_BUSY  <= intake_busy or outlet_busy;          -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process(CLK, RST) begin
        if (RST = '1') then
                curr_addr <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_addr <= (others => '0');
            elsif (intake_start = '1') then
                curr_addr <= I_ADDR;
            elsif (outlet_valid = '1' and O_READY = '1') then
                curr_addr <= std_logic_vector(unsigned(curr_addr) + outlet_size);
            end if;
        end if;
    end process;
end RTL;
