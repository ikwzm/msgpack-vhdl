-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_method_return_code.vhd
--!     @brief   MessagePack-RPC Method Return (Object Encode) Module :
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
entity  MsgPack_RPC_Method_Return_Code is
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
    -- Object Encode Input Interface
    -------------------------------------------------------------------------------
        I_VALID         : in  std_logic;
        I_CODE          : in  MsgPack_RPC.Code_Type;
        I_LAST          : in  std_logic;
        I_READY         : out std_logic
    );
end MsgPack_RPC_Method_Return_Code;
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
architecture RTL of MsgPack_RPC_Method_Return_Code is
    constant  res_shift     :  MsgPack_RPC.Shift_Type := (others => '1');
    constant  ERROR_CODE    :  MsgPack_RPC.Code_Type
                            := MsgPack_RPC.New_Error_Code_Vector_Invalid_Argment(MsgPack_RPC.Code_Length);
    constant  NIL_CODE      :  MsgPack_RPC.Code_Type
                            := MsgPack_Object.New_Code_Vector_Nil(MsgPack_RPC.Code_Length);
    signal    return_code   :  MsgPack_RPC.Code_Type;
    signal    return_valid  :  std_logic;
    signal    return_last   :  std_logic;
    signal    return_ready  :  std_logic;
    signal    return_busy   :  std_logic;
    type      STATE_TYPE    is (IDLE_STATE, ERROR_1st_STATE, ERROR_2nd_STATE, VALUE_1st_STATE, VALUE_2nd_STATE);
    signal    curr_state    :  STATE_TYPE;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
            else
                case curr_state is
                    when IDLE_STATE =>
                        if    (RET_ERROR = '1') then
                            curr_state <= ERROR_1st_STATE;
                        elsif (RET_START = '1') then
                            curr_state <= VALUE_1st_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                    when ERROR_1st_STATE  =>
                        if (return_ready = '1') then
                            curr_state <= ERROR_2nd_STATE;
                        else
                            curr_state <= ERROR_1st_STATE;
                        end if;
                    when ERROR_2nd_STATE =>
                        if (return_ready = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= ERROR_2nd_STATE;
                        end if;
                    when VALUE_1st_STATE  =>
                        if (return_ready = '1') then
                            curr_state <= VALUE_2nd_STATE;
                        else
                            curr_state <= VALUE_1st_STATE;
                        end if;
                    when VALUE_2nd_STATE =>
                        if (I_VALID = '1' and I_LAST = '1' and return_ready = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= VALUE_2nd_STATE;
                        end if;
                    when others =>
                            curr_state <= IDLE_STATE;
                end case;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    return_code  <= ERROR_CODE when (curr_state = ERROR_1st_STATE) else
                    I_CODE     when (curr_state = VALUE_2nd_STATE) else
                    NIL_CODE;
    return_valid <= '1'        when (curr_state = ERROR_1st_STATE) or
                                    (curr_state = ERROR_2nd_STATE) or
                                    (curr_state = VALUE_1st_STATE) or
                                    (curr_state = VALUE_2nd_STATE and I_VALID      = '1') else '0';
    return_last  <= '1'        when (curr_state = ERROR_2nd_STATE) or
                                    (curr_state = VALUE_2nd_STATE and I_LAST       = '1') else '0';
    I_READY      <= '1'        when (curr_state = VALUE_2nd_STATE and return_ready = '1') else '0';
    RET_BUSY     <= '1'        when (curr_state /= IDLE_STATE    or   return_busy  = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    RES_BUF: MsgPack_Object_Code_Reducer                 -- 
        generic map (                                    -- 
            I_WIDTH         => return_code'length      , -- 
            O_WIDTH         => MsgPack_RPC.Code_Length , --
            O_VALID_SIZE    => MsgPack_RPC.Code_Length , -- 
            QUEUE_SIZE      => 0                         -- 
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            DONE            => '0'                     , -- In  :
            BUSY            => return_busy             , -- Out :
            I_ENABLE        => '1'                     , -- In  :
            I_CODE          => return_code             , -- In  :
            I_DONE          => return_last             , -- In  :
            I_VALID         => return_valid            , -- In  :
            I_READY         => return_ready            , -- Out :
            O_ENABLE        => '1'                     , -- In  :
            O_CODE          => RES_CODE                , -- Out :
            O_DONE          => RES_LAST                , -- Out :
            O_VALID         => RES_VALID               , -- Out :
            O_READY         => RES_READY               , -- In  :
            O_SHIFT         => res_shift                 -- In  :
        );                                               --
end RTL;
