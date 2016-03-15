-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_method_return_nil.vhd
--!     @brief   MessagePack-RPC Method Return Nil Module :
--!     @version 0.2.0
--!     @date    2016/3/15
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
use     MsgPack.MsgPack_RPC;
entity  MsgPack_RPC_Method_Return_Nil is
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return Interface
    -------------------------------------------------------------------------------
        RET_ERROR       : in  std_logic;
        RET_START       : in  std_logic;
        RET_BUSY        : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Response Interface
    -------------------------------------------------------------------------------
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic
    );
end MsgPack_RPC_Method_Return_Nil;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_RPC;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Reducer;
architecture RTL of MsgPack_RPC_Method_Return_Nil is
    constant  res_shift     :  MsgPack_RPC.Shift_Type := (others => '1');
    constant  ERROR_CODE    :  MsgPack_Object.Code_Vector(1 downto 0) := (
                   0 => MsgPack_RPC.New_Error_Code_Invalid_Argment,
                   1 => MsgPack_Object.New_Code_Nil
              );
    constant  NIL_CODE      :  MsgPack_Object.Code_Vector(1 downto 0) := (
                   0 => MsgPack_Object.New_Code_Nil,
                   1 => MsgPack_Object.New_Code_Nil
              );
    signal    return_code   :  MsgPack_Object.Code_Vector(1 downto 0);
    signal    return_valid  :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    return_valid <= '1' when (RET_START = '1' or RET_ERROR = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    return_code  <= ERROR_CODE when (RET_ERROR = '1') else
                    NIL_CODE;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    RES_BUF: MsgPack_Object_Code_Reducer                 -- 
        generic map (                                    -- 
            I_WIDTH         => return_code'length      , -- 
            O_WIDTH         => MsgPack_RPC.Code_Length , --
            O_VALID_SIZE    => MsgPack_RPC.Code_Length , -- 
            QUEUE_SIZE      => MsgPack_RPC.Code_Length + return_code'length - 1
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            DONE            => '0'                     , -- In  :
            BUSY            => RET_BUSY                , -- Out :
            I_ENABLE        => '1'                     , -- In  :
            I_CODE          => return_code             , -- In  :
            I_DONE          => '1'                     , -- In  :
            I_VALID         => return_valid            , -- In  :
            I_READY         => open                    , -- Out :
            O_ENABLE        => '1'                     , -- In  :
            O_CODE          => RES_CODE                , -- Out :
            O_DONE          => RES_LAST                , -- Out :
            O_VALID         => RES_VALID               , -- Out :
            O_READY         => RES_READY               , -- In  :
            O_SHIFT         => res_shift                 -- In  :
        );                                               --
end RTL;
