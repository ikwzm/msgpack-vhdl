-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_set_map.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) Set Map Module :
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
entity  MsgPack_KVMap_Set_Map is
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
    -- Key Value Map Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(           CODE_WIDTH-1 downto 0);
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
end MsgPack_KVMap_Set_Map;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Map;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Set_Map_Value;
architecture RTL of MsgPack_KVMap_Set_Map is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_key_code   :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    intake_key_valid  :  std_logic;
    signal    intake_key_last   :  std_logic;
    signal    intake_key_error  :  std_logic;
    signal    intake_key_done   :  std_logic;
    signal    intake_key_shift  :  std_logic_vector          (CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_val_code   :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    intake_val_start  :  std_logic;
    signal    intake_val_abort  :  std_logic;
    signal    intake_val_valid  :  std_logic;
    signal    intake_val_last   :  std_logic;
    signal    intake_val_error  :  std_logic;
    signal    intake_val_done   :  std_logic;
    signal    intake_val_shift  :  std_logic_vector          (CODE_WIDTH-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE_MAP: MsgPack_Object_Decode_Map            -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH            --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
        ---------------------------------------------------------------------------
        -- MessagePack Object Code Input Interface
        ---------------------------------------------------------------------------
            I_CODE          => I_CODE              , -- In  :
            I_LAST          => I_LAST              , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_ERROR         => I_ERROR             , -- Out :
            I_DONE          => I_DONE              , -- Out :
            I_SHIFT         => I_SHIFT             , -- Out :
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            MAP_START       => open                , -- Out :
            MAP_SIZE        => open                , -- Out :
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            KEY_START       => open                , -- Out :
            KEY_VALID       => intake_key_valid    , -- Out :
            KEY_CODE        => intake_key_code     , -- Out :
            KEY_LAST        => intake_key_last     , -- Out :
            KEY_ERROR       => intake_key_error    , -- In  :
            KEY_DONE        => intake_key_done     , -- In  :
            KEY_SHIFT       => intake_key_shift    , -- In  :
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            VALUE_START     => intake_val_start    , -- Out :
            VALUE_ABORT     => intake_val_abort    , -- Out :
            VALUE_VALID     => intake_val_valid    , -- Out :
            VALUE_CODE      => intake_val_code     , -- Out :
            VALUE_LAST      => intake_val_last     , -- Out :
            VALUE_ERROR     => intake_val_error    , -- In  :
            VALUE_DONE      => intake_val_done     , -- In  :
            VALUE_SHIFT     => intake_val_shift      -- In  :
        );                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    SET_VALUE: MsgPack_KVMap_Set_Map_Value           -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH          , --
            STORE_SIZE      => STORE_SIZE          , --
            MATCH_PHASE     => MATCH_PHASE           --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
        ---------------------------------------------------------------------------
        -- Key Object Decode Input Interface
        -------------------------------------------------------------------------------
            I_KEY_CODE      => intake_key_code     , -- In  :
            I_KEY_LAST      => intake_key_last     , -- In  :
            I_KEY_VALID     => intake_key_valid    , -- In  :
            I_KEY_ERROR     => intake_key_error    , -- Out :
            I_KEY_DONE      => intake_key_done     , -- Out :
            I_KEY_SHIFT     => intake_key_shift    , -- Out :
        ---------------------------------------------------------------------------
        -- Value Object Decode Input Interface
        ---------------------------------------------------------------------------
            I_VAL_START     => intake_val_start    , -- In  :
            I_VAL_ABORT     => intake_val_abort    , -- In  :
            I_VAL_CODE      => intake_val_code     , -- In  :
            I_VAL_LAST      => intake_val_last     , -- In  :
            I_VAL_VALID     => intake_val_valid    , -- In  :
            I_VAL_ERROR     => intake_val_error    , -- Out :
            I_VAL_DONE      => intake_val_done     , -- Out :
            I_VAL_SHIFT     => intake_val_shift    , -- Out :
        ---------------------------------------------------------------------------
        -- Key Object Encode Output Interface
        ---------------------------------------------------------------------------
            O_KEY_CODE      => open                , -- Out :
            O_KEY_VALID     => open                , -- Out :
            O_KEY_LAST      => open                , -- Out :
            O_KEY_ERROR     => open                , -- Out :
            O_KEY_READY     => '1'                 , -- In  :
        ---------------------------------------------------------------------------
        -- Key Object Compare Interface
        ---------------------------------------------------------------------------
            MATCH_REQ       => MATCH_REQ           , -- Out :
            MATCH_CODE      => MATCH_CODE          , -- Out :
            MATCH_OK        => MATCH_OK            , -- In  :
            MATCH_NOT       => MATCH_NOT           , -- In  :
            MATCH_SHIFT     => MATCH_SHIFT         , -- In  :
        ---------------------------------------------------------------------------
        -- Value Object Decode Output Interface
        ---------------------------------------------------------------------------
            VALUE_START     => VALUE_START         , -- Out :
            VALUE_VALID     => VALUE_VALID         , -- Out :
            VALUE_CODE      => VALUE_CODE          , -- Out :
            VALUE_LAST      => VALUE_LAST          , -- Out :
            VALUE_ERROR     => VALUE_ERROR         , -- In  :
            VALUE_DONE      => VALUE_DONE          , -- In  :
            VALUE_SHIFT     => VALUE_SHIFT           -- In  :
        );
end RTL;
