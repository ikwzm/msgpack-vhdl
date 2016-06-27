-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_store_map_value.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) Store Map Value Module :
--!     @version 0.2.0
--!     @date    2016/5/17
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
entity  MsgPack_KVMap_Store_Map_Value is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        STORE_SIZE      :  positive := 8;
        MATCH_PHASE     :  positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_KEY_CODE      : in  MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        I_KEY_LAST      : in  std_logic;
        I_KEY_VALID     : in  std_logic;
        I_KEY_ERROR     : out std_logic;
        I_KEY_DONE      : out std_logic;
        I_KEY_SHIFT     : out std_logic_vector(           CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_VAL_START     : in  std_logic;
        I_VAL_ABORT     : in  std_logic;
        I_VAL_CODE      : in  MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        I_VAL_LAST      : in  std_logic;
        I_VAL_VALID     : in  std_logic;
        I_VAL_ERROR     : out std_logic;
        I_VAL_DONE      : out std_logic;
        I_VAL_SHIFT     : out std_logic_vector(           CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_KEY_CODE      : out MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        O_KEY_VALID     : out std_logic;
        O_KEY_LAST      : out std_logic;
        O_KEY_ERROR     : out std_logic;
        O_KEY_READY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Compare Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector(          MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        MATCH_OK        : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        MATCH_NOT       : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        MATCH_SHIFT     : in  std_logic_vector(STORE_SIZE*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Decode Output Interface
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_VALID     : out std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_CODE      : out MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        VALUE_LAST      : out std_logic;
        VALUE_ERROR     : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_DONE      : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_SHIFT     : in  std_logic_vector(STORE_SIZE*CODE_WIDTH-1 downto 0)
    );
end MsgPack_KVMap_Store_Map_Value;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Dispatcher;
architecture RTL of MsgPack_KVMap_Store_Map_Value is
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DISPATCH: MsgPack_KVMap_Dispatcher           -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , --
            STORE_SIZE      => STORE_SIZE      , --
            MATCH_PHASE     => MATCH_PHASE       --
        )                                        -- 
        port map (                               -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
        ---------------------------------------------------------------------------
        -- Key Object Decode Input Interface
        ---------------------------------------------------------------------------
            I_KEY_CODE      => I_KEY_CODE      , -- In  :
            I_KEY_LAST      => I_KEY_LAST      , -- In  :
            I_KEY_VALID     => I_KEY_VALID     , -- In  :
            I_KEY_ERROR     => I_KEY_ERROR     , -- Out :
            I_KEY_DONE      => I_KEY_DONE      , -- Out :
            I_KEY_SHIFT     => I_KEY_SHIFT     , -- Out :
        ---------------------------------------------------------------------------
        -- Value Object Decode Input Interface
        ---------------------------------------------------------------------------
            I_VAL_START     => I_VAL_START     , -- In  :
            I_VAL_ABORT     => I_VAL_ABORT     , -- In  :
            I_VAL_CODE      => I_VAL_CODE      , -- In  :
            I_VAL_LAST      => I_VAL_LAST      , -- In  :
            I_VAL_VALID     => I_VAL_VALID     , -- In  :
            I_VAL_ERROR     => I_VAL_ERROR     , -- Out :
            I_VAL_DONE      => I_VAL_DONE      , -- Out :
            I_VAL_SHIFT     => I_VAL_SHIFT     , -- Out :
        ---------------------------------------------------------------------------
        -- Key Object Encode Output Interface
        ---------------------------------------------------------------------------
            O_KEY_CODE      => O_KEY_CODE      , -- Out :
            O_KEY_VALID     => O_KEY_VALID     , -- Out :
            O_KEY_LAST      => O_KEY_LAST      , -- Out :
            O_KEY_ERROR     => O_KEY_ERROR     , -- Out :
            O_KEY_READY     => O_KEY_READY     , -- In  :
        ---------------------------------------------------------------------------
        -- Key Object Compare Interface
        ---------------------------------------------------------------------------
            MATCH_REQ       => MATCH_REQ       , -- Out :
            MATCH_CODE      => MATCH_CODE      , -- Out :
            MATCH_OK        => MATCH_OK        , -- In  :
            MATCH_NOT       => MATCH_NOT       , -- In  :
            MATCH_SHIFT     => MATCH_SHIFT     , -- In  :
        ---------------------------------------------------------------------------
        -- Value Object Decode Output Interface
        ---------------------------------------------------------------------------
            VALUE_START     => VALUE_START     , -- Out :
            VALUE_VALID     => VALUE_VALID     , -- Out :
            VALUE_CODE      => VALUE_CODE      , -- Out :
            VALUE_LAST      => VALUE_LAST      , -- Out :
            VALUE_ERROR     => VALUE_ERROR     , -- In  :
            VALUE_DONE      => VALUE_DONE      , -- In  :
            VALUE_SHIFT     => VALUE_SHIFT     , -- In  :
        ---------------------------------------------------------------------------
        -- Dispatch Control/Status Interface
        ---------------------------------------------------------------------------
            DISPATCH_SELECT => open            , -- Out :
            DISPATCH_START  => open            , -- Out :
            DISPATCH_ERROR  => open            , -- Out :
            DISPATCH_ABORT  => open            , -- Out :
            DISPATCH_BUSY   => '0'               -- In  :
        );
end RTL;
