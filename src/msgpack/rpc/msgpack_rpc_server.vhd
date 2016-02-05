-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_server.vhd
--!     @brief   MessagePack-RPC Server Module :
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
use     MsgPack.MsgPack_RPC;
entity  MsgPack_RPC_Server is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        I_BYTES         : positive := 1;
        O_BYTES         : positive := 1;
        PROC_NUM        : positive := 1;
        MATCH_PHASE     : positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Byte Data Stream Input Interface
    -------------------------------------------------------------------------------
        I_DATA          : in  std_logic_vector(8*I_BYTES-1 downto 0);
        I_STRB          : in  std_logic_vector(  I_BYTES-1 downto 0);
        I_LAST          : in  std_logic := '0';
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Byte Data Stream Output Interface
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(8*O_BYTES-1 downto 0);
        O_STRB          : out std_logic_vector(  O_BYTES-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector     (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_RPC.Code_Type;
        MATCH_OK        : in  std_logic_vector        (PROC_NUM-1 downto 0);
        MATCH_NOT       : in  std_logic_vector        (PROC_NUM-1 downto 0);
        MATCH_SHIFT     : in  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Request Interface
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : out MsgPack_RPC.MsgID_Type;
        PROC_REQ        : out std_logic_vector        (PROC_NUM-1 downto 0);
        PROC_BUSY       : in  std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_VALID     : out std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_CODE      : out MsgPack_RPC.Code_Vector (PROC_NUM-1 downto 0);
        PARAM_LAST      : out std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_SHIFT     : in  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Response Interface
    -------------------------------------------------------------------------------
        PROC_RES_ID     : in  MsgPack_RPC.MsgID_Vector(PROC_NUM-1 downto 0);
        PROC_RES_CODE   : in  MsgPack_RPC.Code_Vector (PROC_NUM-1 downto 0);
        PROC_RES_VALID  : in  std_logic_vector        (PROC_NUM-1 downto 0);
        PROC_RES_LAST   : in  std_logic_vector        (PROC_NUM-1 downto 0);
        PROC_RES_READY  : out std_logic_vector        (PROC_NUM-1 downto 0)
    );
end  MsgPack_RPC_Server;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_RPC;
use     MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Server_Requester;
use     MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Server_Responder;
architecture RTL of MsgPack_RPC_Server is
    signal    res_id            :  MsgPack_RPC.MsgID_Vector(PROC_NUM downto 0);
    signal    res_code          :  MsgPack_RPC.Code_Vector (PROC_NUM downto 0);
    signal    res_valid         :  std_logic_vector        (PROC_NUM downto 0);
    signal    res_last          :  std_logic_vector        (PROC_NUM downto 0);
    signal    res_ready         :  std_logic_vector        (PROC_NUM downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    REQ: MsgPack_RPC_Server_Requester            -- 
        generic map (                            -- 
            I_BYTES         => I_BYTES         , --
            PROC_NUM        => PROC_NUM        , --
            MATCH_PHASE     => MATCH_PHASE       --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            I_DATA          => I_DATA          , -- In  :
            I_STRB          => I_STRB          , -- In  :
            I_LAST          => I_LAST          , -- In  :
            I_VALID         => I_VALID         , -- In  :
            I_READY         => I_READY         , -- Out :
            MATCH_REQ       => MATCH_REQ       , -- Out :
            MATCH_CODE      => MATCH_CODE      , -- Out :
            MATCH_OK        => MATCH_OK        , -- In  :
            MATCH_NOT       => MATCH_NOT       , -- In  :
            MATCH_SHIFT     => MATCH_SHIFT     , -- In  :
            PROC_REQ_ID     => PROC_REQ_ID     , -- Out :
            PROC_REQ        => PROC_REQ        , -- Out :
            PROC_BUSY       => PROC_BUSY       , -- In  :
            PARAM_VALID     => PARAM_VALID     , -- Out :
            PARAM_CODE      => PARAM_CODE      , -- Out :
            PARAM_LAST      => PARAM_LAST      , -- Out :
            PARAM_SHIFT     => PARAM_SHIFT     , -- In  :
            ERROR_RES_ID    => res_id(0)       , -- Out :
            ERROR_RES_CODE  => res_code(0)     , -- Out :
            ERROR_RES_VALID => res_valid(0)    , -- Out :
            ERROR_RES_LAST  => res_last(0)     , -- Out :
            ERROR_RES_READY => res_ready(0)      -- In  :
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    RES: MsgPack_RPC_Server_Responder            -- 
        generic map (                            -- 
            O_BYTES         => O_BYTES         , --
            RES_NUM         => PROC_NUM+1        --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            O_DATA          => O_DATA          , -- Out :
            O_STRB          => O_STRB          , -- Out :
            O_LAST          => O_LAST          , -- Out :
            O_VALID         => O_VALID         , -- Out :
            O_READY         => O_READY         , -- In  :
            RES_ID          => res_id          , -- In  :
            RES_CODE        => res_code        , -- In  :
            RES_VALID       => res_valid       , -- In  :
            RES_LAST        => res_last        , -- In  :
            RES_READY       => res_ready         -- Out :
        );
    RES_GEN: for i in 1 to PROC_NUM generate
        res_id   (i) <= PROC_RES_ID   (i-1);
        res_code (i) <= PROC_RES_CODE (i-1);
        res_valid(i) <= PROC_RES_VALID(i-1);
        res_last (i) <= PROC_RES_LAST (i-1);
        PROC_RES_READY(i-1) <= res_ready(i);
    end generate;
end RTL;
