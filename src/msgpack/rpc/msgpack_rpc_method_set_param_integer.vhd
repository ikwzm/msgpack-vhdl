-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_method_set_param_integer.vhd
--!     @brief   MessagePack-RPC Method Set Parameter (Integer) Module :
--!     @version 0.1.0
--!     @date    2015/10/19
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
entity  MsgPack_RPC_Method_Set_Param_Integer is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        VALUE_WIDTH     :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE;
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
    -- MessagePack-RPC Method Set Parameter Interface
    -------------------------------------------------------------------------------
        SET_PARAM_CODE  : in  MsgPack_RPC.Code_Type;
        SET_PARAM_LAST  : in  std_logic;
        SET_PARAM_VALID : in  std_logic;
        SET_PARAM_ERROR : out std_logic;
        SET_PARAM_DONE  : out std_logic;
        SET_PARAM_SHIFT : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- Default Value Input Interface
    -------------------------------------------------------------------------------
        DEFAULT_VALUE   : in  std_logic_vector(VALUE_WIDTH-1 downto 0);
        DEFAULT_WE      : in  std_logic;
    -------------------------------------------------------------------------------
    -- Parameter Value Output Interface
    -------------------------------------------------------------------------------
        PARAM_VALUE     : out std_logic_vector(VALUE_WIDTH-1 downto 0);
        PARAM_WE        : out std_logic
    );
end  MsgPack_RPC_Method_Set_Param_Integer;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_RPC;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Integer;
architecture RTL of MsgPack_RPC_Method_Set_Param_Integer is
    signal    value_din         :  std_logic_vector(VALUE_WIDTH-1 downto 0);
    signal    value_load        :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE: MsgPack_Object_Decode_Integer                -- 
        generic map (                                    -- 
            CODE_WIDTH      => MsgPack_RPC.Code_Length , --
            VALUE_WIDTH     => VALUE_WIDTH             , --
            VALUE_SIGN      => VALUE_SIGN              , --
            CHECK_RANGE     => CHECK_RANGE             , --
            ENABLE64        => ENABLE64                  --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- : In  :
            RST             => RST                     , -- : In  :
            CLR             => CLR                     , -- : In  :
            I_CODE          => SET_PARAM_CODE          , -- : In  :
            I_LAST          => SET_PARAM_LAST          , -- : In  :
            I_VALID         => SET_PARAM_VALID         , -- : In  :
            I_ERROR         => SET_PARAM_ERROR         , -- : Out :
            I_DONE          => SET_PARAM_DONE          , -- : Out :
            I_SHIFT         => SET_PARAM_SHIFT         , -- : Out :
            VALUE           => value_din               , -- : Out :
            WE              => value_load                -- : Out :
        );                                               --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                PARAM_VALUE <= (others => '0');
                PARAM_WE    <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                PARAM_VALUE <= (others => '0');
                PARAM_WE    <= '0';
            elsif (DEFAULT_WE = '1') then
                PARAM_VALUE <= DEFAULT_VALUE;
                PARAM_WE    <= '1';
            elsif (value_load = '1') then
                PARAM_VALUE <= value_din;
                PARAM_WE    <= '1';
            else
                PARAM_WE    <= '0';
            end if;
        end if;
    end process;
end RTL;

