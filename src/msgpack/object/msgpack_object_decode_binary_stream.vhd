-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_binary_stream.vhd
--!     @brief   MessagePack Object decode to binary/string stream
--!     @version 0.2.0
--!     @date    2015/11/9
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
entity  MsgPack_Object_Decode_Binary_Stream is
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
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH -1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Output Interface
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(DATA_BITS  -1 downto 0);
        O_STRB          : out std_logic_vector(DATA_BITS/8-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end  MsgPack_Object_Decode_Binary_Stream;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_ComponentMsgPack_Object_Decode_Binary_Core;
use     MsgPack.PipeWork_Components.REDUCER;
architecture RTL of MsgPack_Object_Decode_Binary_Stream is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  OUTLET_BYTES        :  integer := DATA_BITS/8;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  INTAKE_BITS       :  integer := CODE_WIDTH * MsgPack_Object.CODE_DATA_BITS;
    constant  INTAKE_BYTES      :  integer := CODE_WIDTH * MsgPack_Object.CODE_DATA_BYTES;
    signal    intake_enable     :  std_logic;
    signal    intake_valid      :  std_logic;
    signal    intake_last       :  std_logic;
    signal    intake_ready      :  std_logic;
    signal    intake_strb       :  std_logic_vector(INTAKE_BYTES-1 downto 0);
    signal    intake_data       :  std_logic_vector(INTAKE_BITS -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  gcd(A,B:integer) return integer is
        variable x,y,r: integer;
    begin
        if (A>B) then
            x := A;
            y := B;
        else
            x := B;
            y := A;
        end if;
        while y > 0 loop
            r := x mod y;
            x := y;
            y := r;
        end loop;
        return x;
    end function;
    constant  WORD_BYTES        :  integer := gcd(OUTLET_BYTES, INTAKE_BYTES);
    constant  WORD_BITS         :  integer := 8*WORD_BYTES;
    constant  OUTLET_WORDS      :  integer := OUTLET_BYTES / WORD_BYTES;
    constant  INTAKE_WORDS      :  integer := INTAKE_BYTES / WORD_BYTES;
    constant  outlet_offset     :  std_logic_vector(OUTLET_WORDS-1 downto 0) := (others => '0');
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
            O_START         => open              , -- Out :
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
    OUTLET: REDUCER                                 -- 
        generic map (                               -- 
            WORD_BITS       => WORD_BITS          , -- 1 byte(8bit)
            STRB_BITS       => WORD_BYTES         , -- 1 bit
            I_WIDTH         => INTAKE_WORDS       , -- 
            O_WIDTH         => OUTLET_WORDS       , -- Output Byte Size
            QUEUE_SIZE      => 0                  , -- Queue size is auto
            VALID_MIN       => 0                  , -- VALID unused
            VALID_MAX       => 0                  , -- VALID unused
            O_VAL_SIZE      => OUTLET_WORDS       , -- 
            O_SHIFT_MIN     => OUTLET_WORDS       , -- SHIFT unused
            O_SHIFT_MAX     => OUTLET_WORDS       , -- SHIFT unused
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
            START           => '0'                , -- In  :
            OFFSET          => outlet_offset      , -- In  :
            DONE            => '0'                , -- In  :
            FLUSH           => '0'                , -- In  :
            BUSY            => open               , -- Out :
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
            O_STRB          => O_STRB             , -- Out :
            O_DONE          => O_LAST             , -- Out :
            O_FLUSH         => open               , -- Out :
            O_VAL           => O_VALID            , -- Out :
            O_RDY           => O_READY            , -- In  :
            O_SHIFT         => "0"                  -- In  :
    );                                              --
end RTL;
