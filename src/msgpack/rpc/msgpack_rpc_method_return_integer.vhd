-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_method_return_integer.vhd
--!     @brief   MessagePack-RPC Method Return (Integer Type) Module :
--!     @version 0.2.0
--!     @date    2016/5/20
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
entity  MsgPack_RPC_Method_Return_Integer is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        VALUE_WIDTH     :  positive := 32;
        RETURN_UINT     :  boolean  := TRUE;
        RETURN_INT      :  boolean  := TRUE;
        RETURN_FLOAT    :  boolean  := TRUE;
        RETURN_BOOLEAN  :  boolean  := TRUE
    );
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
        RET_DONE        : in  std_logic;
        RET_BUSY        : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Response Interface
    -------------------------------------------------------------------------------
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- Return Value
    -------------------------------------------------------------------------------
        VALUE           : in  std_logic_vector(VALUE_WIDTH-1 downto 0)
    );
end MsgPack_RPC_Method_Return_Integer;
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
architecture RTL of MsgPack_RPC_Method_Return_Integer is
    constant  RESULT_WIDTH  :  integer := (VALUE'length+MsgPack_Object.CODE_DATA_BITS-1)/MsgPack_Object.CODE_DATA_BITS;
    signal    return_code   :  MsgPack_Object.Code_Vector(RESULT_WIDTH downto 0);
    constant  res_shift     :  MsgPack_RPC.Shift_Type := (others => '1');
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (RET_ERROR, VALUE) begin
        if    (RET_ERROR = '1') then
            return_code(0)                     <= MsgPack_RPC.New_Error_Code_Invalid_Argment;
            return_code(RESULT_WIDTH downto 1) <= MsgPack_Object.New_Code_Vector_Nil    (RESULT_WIDTH);
        elsif (RETURN_INT) then
            return_code(0)                     <= MsgPack_Object.New_Code_Nil;
            return_code(RESULT_WIDTH downto 1) <= MsgPack_Object.New_Code_Vector_Integer(RESULT_WIDTH, signed(VALUE));
        elsif (RETURN_FLOAT) then
            return_code(0)                     <= MsgPack_Object.New_Code_Nil;
            return_code(RESULT_WIDTH downto 1) <= MsgPack_Object.New_Code_Vector_Float  (RESULT_WIDTH, VALUE);
        elsif (RETURN_BOOLEAN and VALUE(0) = '1') then
            return_code(0)                     <= MsgPack_Object.New_Code_Nil;
            return_code(RESULT_WIDTH downto 1) <= MsgPack_Object.New_Code_Vector_True   (RESULT_WIDTH);
        elsif (RETURN_BOOLEAN and VALUE(0) = '0') then
            return_code(0)                     <= MsgPack_Object.New_Code_Nil;
            return_code(RESULT_WIDTH downto 1) <= MsgPack_Object.New_Code_Vector_False  (RESULT_WIDTH);
        else
            return_code(0)                     <= MsgPack_Object.New_Code_Nil;
            return_code(RESULT_WIDTH downto 1) <= MsgPack_Object.New_Code_Vector_Integer(RESULT_WIDTH, unsigned(VALUE));
        end if;
    end process;
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
            I_VALID         => RET_DONE                , -- In  :
            I_READY         => open                    , -- Out :
            O_ENABLE        => '1'                     , -- In  :
            O_CODE          => RES_CODE                , -- Out :
            O_DONE          => RES_LAST                , -- Out :
            O_VALID         => RES_VALID               , -- Out :
            O_READY         => RES_READY               , -- In  :
            O_SHIFT         => res_shift                 -- In  :
        );                                               --
end RTL;
