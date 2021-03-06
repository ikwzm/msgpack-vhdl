-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_boolean_stream.vhd
--!     @brief   MessagePack Object decode to boolean stream
--!     @version 0.2.0
--!     @date    2016/6/23
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
entity  MsgPack_Object_Decode_Boolean_Stream is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 1;
        SIZE_BITS       :  positive := 32
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
    -- Boolean Value Data and Address Output
    -------------------------------------------------------------------------------
        O_START         : out std_logic;
        O_BUSY          : out std_logic;
        O_SIZE          : out std_logic_vector(SIZE_BITS-1 downto 0);
        O_DATA          : out std_logic_vector(DATA_BITS-1 downto 0);
        O_STRB          : out std_logic_vector(DATA_BITS-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end  MsgPack_Object_Decode_Boolean_Stream;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Array;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Boolean;
use     MsgPack.PipeWork_Components.REDUCER;
architecture RTL of MsgPack_Object_Decode_Boolean_Stream is
    constant  OUTLET_WORDS      :  integer := DATA_BITS;
    constant  intake_offset     :  std_logic_vector(OUTLET_WORDS-1 downto 0) := (others => '0');
    signal    intake_busy       :  std_logic;
    signal    intake_valid      :  std_logic;
    signal    intake_error      :  std_logic;
    signal    intake_done       :  std_logic;
    signal    intake_last       :  std_logic;
    signal    intake_code       :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    intake_shift      :  std_logic_vector(CODE_WIDTH-1 downto 0);
    signal    value_valid       :  std_logic;
    signal    value_ready       :  std_logic;
    signal    value_data        :  std_logic_vector(0 downto 0);
    constant  value_strb        :  std_logic_vector(0 downto 0) := (others => '1');
    signal    value_last        :  std_logic;
    signal    outlet_busy       :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE_ARRAY:  MsgPack_Object_Decode_Array       -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH          , --
            SIZE_BITS       => SIZE_BITS             -- 
        )                                            -- 
        port map (                                   -- 
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
            ENABLE          => '1'                 , -- In  :
            BUSY            => open                , -- Out :
            READY           => open                , -- Out :
            I_CODE          => I_CODE              , -- In  :
            I_LAST          => I_LAST              , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_ERROR         => I_ERROR             , -- Out :
            I_DONE          => I_DONE              , -- Out :
            I_SHIFT         => I_SHIFT             , -- Out :
            ARRAY_START     => open                , -- Out :
            ARRAY_SIZE      => open                , -- Out :
            ENTRY_START     => O_START             , -- Out :
            ENTRY_BUSY      => intake_busy         , -- Out :
            ENTRY_LAST      => open                , -- Out :
            ENTRY_SIZE      => O_SIZE              , -- Out :
            VALUE_START     => open                , -- Out :
            VALUE_VALID     => intake_valid        , -- Out :
            VALUE_CODE      => intake_code         , -- Out :
            VALUE_LAST      => intake_last         , -- Out :
            VALUE_ERROR     => intake_error        , -- In  :
            VALUE_DONE      => intake_done         , -- In  :
            VALUE_SHIFT     => intake_shift          -- In  :
        );                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE_VALUE: MsgPack_Object_Decode_Boolean      -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH            --
        )                                            -- 
        port map (                                   -- 
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
            I_CODE          => intake_code         , -- In  :
            I_LAST          => intake_last         , -- In  :
            I_VALID         => intake_valid        , -- In  :
            I_ERROR         => intake_error        , -- Out :
            I_DONE          => intake_done         , -- Out :
            I_SHIFT         => intake_shift        , -- Out :
            O_VALUE         => value_data(0)       , -- Out :
            O_LAST          => value_last          , -- Out :
            O_VALID         => value_valid         , -- Out :
            O_READY         => value_ready           -- In  :
        );                                           --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    OUTLET: REDUCER                                 -- 
        generic map (                               -- 
            WORD_BITS       => 1                  , -- 1 byte(1bit)
            STRB_BITS       => 1                  , -- 1 bit
            I_WIDTH         => 1                  , -- 
            O_WIDTH         => OUTLET_WORDS       , -- Output Data Size
            QUEUE_SIZE      => 0                  , -- Queue size is auto
            VALID_MIN       => 0                  , -- VALID unused
            VALID_MAX       => 0                  , -- VALID unused
            O_VAL_SIZE      => OUTLET_WORDS       , -- 
            O_SHIFT_MIN     => OUTLET_WORDS       , -- SHIFT unused
            O_SHIFT_MAX     => OUTLET_WORDS       , -- SHIFT unused
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
            BUSY            => outlet_busy        , -- Out :
            VALID           => open               , -- Out :
        ---------------------------------------------------------------------------
        -- Byte Stream Input Interface
        ---------------------------------------------------------------------------
            I_ENABLE        => '1'                , -- In  :
            I_STRB          => value_strb         , -- In  :
            I_DATA          => value_data         , -- In  :
            I_DONE          => value_last         , -- In  :
            I_FLUSH         => '0'                , -- In  :
            I_VAL           => value_valid        , -- In  :
            I_RDY           => value_ready        , -- Out :
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
        );                                          --
    O_BUSY <= '1' when (intake_busy = '1' or outlet_busy = '1') else '0';
end RTL;
