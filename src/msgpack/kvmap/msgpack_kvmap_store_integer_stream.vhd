-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_store_integer_stream.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) Store Integer Stream Module :
--!     @version 0.2.0
--!     @date    2016/6/6
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
entity  MsgPack_KVMap_Store_Integer_Stream is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        KEY             :  STRING;
        CODE_WIDTH      :  positive := 1;
        MATCH_PHASE     :  positive := 8;
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
    -- MessagePack Key Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Data and Address Output
    -------------------------------------------------------------------------------
        START           : out std_logic;
        BUSY            : out std_logic;
        VALUE           : out std_logic_vector(VALUE_BITS-1 downto 0);
        SIGN            : out std_logic;
        LAST            : out std_logic;
        VALID           : out std_logic;
        READY           : in  std_logic
    );
end  MsgPack_KVMap_Store_Integer_Stream;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Integer_Stream;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Key_Compare;
architecture RTL of MsgPack_KVMap_Store_Integer_Stream is
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    MATCH: MsgPack_KVMap_Key_Compare             -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , -- 
            I_MAX_PHASE     => MATCH_PHASE     , --
            KEYWORD         => KEY               --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- 
            RST             => RST             , -- 
            CLR             => CLR             , -- 
            I_CODE          => MATCH_CODE      , -- 
            I_REQ_PHASE     => MATCH_REQ       , -- 
            MATCH           => MATCH_OK        , -- 
            MISMATCH        => MATCH_NOT       , -- 
            SHIFT           => MATCH_SHIFT       -- 
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE: MsgPack_Object_Decode_Integer_Stream -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , --
            VALUE_BITS      => VALUE_BITS      , --
            VALUE_SIGN      => VALUE_SIGN      , --
            CHECK_RANGE     => CHECK_RANGE     , --
            ENABLE64        => ENABLE64          --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            I_CODE          => I_CODE          , -- In  :
            I_LAST          => I_LAST          , -- In  :
            I_VALID         => I_VALID         , -- In  :
            I_ERROR         => I_ERROR         , -- Out :
            I_DONE          => I_DONE          , -- Out :
            I_SHIFT         => I_SHIFT         , -- Out :
            O_START         => START           , -- Out :
            O_BUSY          => BUSY            , -- Out :
            O_VALUE         => VALUE           , -- Out :
            O_SIGN          => SIGN            , -- Out :
            O_LAST          => LAST            , -- Out :
            O_VALID         => VALID           , -- Out :
            O_READY         => READY             -- In  :
        );                                       --
end RTL;
