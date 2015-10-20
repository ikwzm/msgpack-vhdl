-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_key_compare.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) Key Compare :
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
entity  MsgPack_KVMap_Key_Compare is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      : positive := 1;
        I_MAX_PHASE     : positive := 1;
        KEYWORD         : string
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Input Object Code Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_REQ_PHASE     : in  std_logic_vector(I_MAX_PHASE-1 downto 0);
    -------------------------------------------------------------------------------
    -- Compare Result Output
    -------------------------------------------------------------------------------
        MATCH           : out std_logic;
        MISMATCH        : out std_logic;
        SHIFT           : out std_logic_vector(CODE_WIDTH-1 downto 0)
    );
end MsgPack_KVMap_Key_Compare;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Compare;
architecture RTL of MsgPack_KVMap_Key_Compare is
    constant  CODE_DATA_BYTES    :  integer := MsgPack_Object.CODE_DATA_BYTES;
    constant  STR_CODE_WIDTH     :  integer := (KEYWORD'length+CODE_DATA_BYTES-1)/CODE_DATA_BYTES + 1;
    constant  STR_CODE           :  MsgPack_Object.Code_Vector(STR_CODE_WIDTH-1 downto 0)
                                 := MsgPack_Object.New_Code_Vector_String(STR_CODE_WIDTH, KEYWORD);
begin
    COMP: MsgPack_Object_Code_Compare            -- 
        generic map (                            -- 
            C_WIDTH         => STR_CODE_WIDTH  , -- 
            I_WIDTH         => CODE_WIDTH      , -- 
            I_MAX_PHASE     => I_MAX_PHASE       -- 
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            I_CODE          => I_CODE          , -- In  :
            I_REQ_PHASE     => I_REQ_PHASE     , -- In  :
            C_CODE          => STR_CODE        , -- In  :
            MATCH           => MATCH           , -- Out :
            MISMATCH        => MISMATCH        , -- Out :
            SHIFT           => SHIFT             -- Out :
        );
end RTL;
