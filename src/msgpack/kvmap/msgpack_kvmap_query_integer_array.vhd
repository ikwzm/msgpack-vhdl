-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_query_integer_array.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) Queary Integer Array Module :
--!     @version 0.2.0
--!     @date    2016/6/10
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
entity  MsgPack_KVMap_Query_Integer_Array is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        KEY             :  STRING;
        CODE_WIDTH      :  positive := 1;
        MATCH_PHASE     :  positive := 8;
        ADDR_BITS       :  positive := 32;
        SIZE_BITS       :  integer range 1 to 32 := 32;
        VALUE_BITS      :  integer range 1 to 64 := 32;
        VALUE_SIGN      :  boolean  := FALSE
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Default(when parameter == nil) Query Size 
    -------------------------------------------------------------------------------
        DEFAULT_SIZE    : in  std_logic_vector( SIZE_BITS-1 downto 0) := (others => '1');
    -------------------------------------------------------------------------------
    -- Object Code Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack Key Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Input Interface
    -------------------------------------------------------------------------------
        START           : out std_logic;
        BUSY            : out std_logic;
        SIZE            : out std_logic_vector( SIZE_BITS-1 downto 0);
        ADDR            : out std_logic_vector( ADDR_BITS-1 downto 0);
        VALUE           : in  std_logic_vector(VALUE_BITS-1 downto 0);
        VALID           : in  std_logic;
        READY           : out std_logic
    );
end  MsgPack_KVMap_Query_Integer_Array;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Query_Integer_Array;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Key_Compare;
architecture RTL of MsgPack_KVMap_Query_Integer_Array is
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
    QUERY: MsgPack_Object_Query_Integer_Array    -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , --
            ADDR_BITS       => ADDR_BITS       , --
            SIZE_BITS       => SIZE_BITS       , -- 
            VALUE_BITS      => VALUE_BITS      , --
            VALUE_SIGN      => VALUE_SIGN        --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            DEFAULT_SIZE    => DEFAULT_SIZE    , -- In  :
            I_CODE          => I_CODE          , -- In  :
            I_LAST          => I_LAST          , -- In  :
            I_VALID         => I_VALID         , -- In  :
            I_ERROR         => I_ERROR         , -- Out :
            I_DONE          => I_DONE          , -- Out :
            I_SHIFT         => I_SHIFT         , -- Out :
            O_CODE          => O_CODE          , -- Out :
            O_VALID         => O_VALID         , -- Out :
            O_LAST          => O_LAST          , -- Out :
            O_ERROR         => O_ERROR         , -- Out :
            O_READY         => O_READY         , -- In  :
            START           => START           , -- Out :
            BUSY            => BUSY            , -- Out :
            SIZE            => SIZE            , -- Out :
            ADDR            => ADDR            , -- Out :
            VALUE           => VALUE           , -- In  :
            VALID           => VALID           , -- In  :
            READY           => READY             -- Out :
        );
end RTL;
