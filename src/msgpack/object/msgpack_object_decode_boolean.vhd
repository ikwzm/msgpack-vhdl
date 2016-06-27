-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_boolean.vhd
--!     @brief   MessagePack Object Decode to Boolean
--!     @version 0.2.0
--!     @date    2016/6/15
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2016 Ichiro Kawazome
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
entity  MsgPack_Object_Decode_Boolean is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1
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
    -- Integer Value Output Interface
    -------------------------------------------------------------------------------
        O_VALUE         : out std_logic;
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end  MsgPack_Object_Decode_Boolean;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Decode_Boolean is
    signal   ii_valid    :  std_logic;
    signal   ii_shift    :  std_logic;
    signal   ii_ready    :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (I_VALID, I_CODE, ii_ready) begin
        if (I_VALID = '1' and I_CODE(0).valid = '1' and ii_ready = '1') then
            if  (I_CODE(0).class = MsgPack_Object.CLASS_BOOLEAN) and
                (I_CODE(0).complete = '1') then
                I_ERROR  <= '0';
                I_DONE   <= '1';
                ii_shift <= '1';
                ii_valid <= '1';
            else
                I_ERROR  <= '1';
                I_DONE   <= '1';
                ii_shift <= '0';
                ii_valid <= '0';
            end if;
        else
                I_ERROR  <= '0';
                I_DONE   <= '0';
                ii_shift <= '0';
                ii_valid <= '0';
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- I_SHIFT
    -------------------------------------------------------------------------------
    process (ii_shift) begin
        for i in I_SHIFT'range loop
            if (i = 0) then
                I_SHIFT(i) <= ii_shift;
            else
                I_SHIFT(i) <= '0';
            end if;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    O_VALUE  <= '1' when (I_CODE(0).data(0) = '1') else '0';
    O_VALID  <= '1' when (ii_valid          = '1') else '0';
    O_LAST   <= '1' when (I_LAST            = '1') else '0';
    ii_ready <= '1' when (O_READY           = '1') else '0';
end RTL;
