-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc.vhd
--!     @brief   MessagePack-RPC(Remote Procedure Call) Package :
--!     @version 0.3.0
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
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
package MsgPack_RPC is

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  Code_Length       :  integer := 1;

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   Code_Type         is MsgPack_Object.Code_Vector(Code_Length-1 downto 0);
    type      Code_Vector       is array (integer range <>) of Code_Type;
    constant  Code_Null         :  Code_Type  := (others => MsgPack_Object.CODE_NULL);

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   Shift_Type        is std_logic_vector(Code_Length-1 downto 0);
    type      Shift_Vector      is array (integer range <>) of Shift_Type;
    constant  Shift_Null        :  Shift_Type := (others => '0');
    function  To_Shift_Type(Num:integer) return Shift_Type;

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   MsgID_Type        is std_logic_vector(31 downto 0);
    type      MsgID_Vector      is array (integer range <>) of MsgID_Type;
    constant  MsgID_Null        :  MsgID_Type := (others => '0');
    
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  ERROR_CODE_PROC_BUSY       :  integer := 0;
    constant  ERROR_CODE_NO_METHOD       :  integer := 1;
    constant  ERROR_CODE_INVALID_ARGMENT :  integer := 2;
    constant  ERROR_CODE_INVALID_MESSAGE :  integer := 3;

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Error_Code(CODE:integer)   return MsgPack_Object.Code_Type;
    constant  New_Error_Code_Proc_Busy       : MsgPack_Object.Code_Type := New_Error_Code(ERROR_CODE_PROC_BUSY);
    constant  New_Error_Code_No_Method       : MsgPack_Object.Code_Type := New_Error_Code(ERROR_CODE_NO_METHOD);
    constant  New_Error_Code_Invalid_Argment : MsgPack_Object.Code_Type := New_Error_Code(ERROR_CODE_INVALID_ARGMENT);
    constant  New_Error_Code_Invalid_Message : MsgPack_Object.Code_Type := New_Error_Code(ERROR_CODE_INVALID_MESSAGE);

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Error_Code_Vector   (CODE:integer;LENGTH:integer) return MsgPack_Object.Code_Vector;
    function  New_Error_Code_Vector_Proc_Busy      (LENGTH:integer) return MsgPack_Object.Code_Vector;
    function  New_Error_Code_Vector_No_Method      (LENGTH:integer) return MsgPack_Object.Code_Vector;
    function  New_Error_Code_Vector_Invalid_Argment(LENGTH:integer) return MsgPack_Object.Code_Vector;
    function  New_Error_Code_Vector_Invalid_Message(LENGTH:integer) return MsgPack_Object.Code_Vector;

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  Is_Error_Code    (NUM:integer;CODE:MsgPack_Object.Code_Type) return boolean;
    function  Is_Error_Code_Proc_Busy      (CODE:MsgPack_Object.Code_Type) return boolean;
    function  Is_Error_Code_No_Method      (CODE:MsgPack_Object.Code_Type) return boolean;
    function  Is_Error_Code_Invalid_Argment(CODE:MsgPack_Object.Code_Type) return boolean;
    function  Is_Error_Code_Invalid_Message(CODE:MsgPack_Object.Code_Type) return boolean;

    
end MsgPack_RPC;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
package body MsgPack_RPC is

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  To_Shift_Type(Num:integer) return Shift_Type is
        variable shift :  Shift_Type;
    begin
        for i in shift'range loop
            if (i < Num) then
                shift(i) := '1';
            else
                shift(i) := '0';
            end if;
        end loop;
        return shift;
    end function;

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Error_Code(CODE:integer)   return MsgPack_Object.Code_Type is begin 
        return MsgPack_Object.New_Code_Reserve(CODE);
    end function;

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Error_Code_Vector   (CODE:integer;LENGTH:integer) return MsgPack_Object.Code_Vector is
    begin
        return MsgPack_Object.New_Code_Vector_Reserve(LENGTH,CODE);
    end function;

    function  New_Error_Code_Vector_Proc_Busy      (LENGTH:integer) return MsgPack_Object.Code_Vector is
    begin
        return New_Error_Code_Vector(ERROR_CODE_PROC_BUSY, LENGTH);
    end function;

    function  New_Error_Code_Vector_No_Method      (LENGTH:integer) return MsgPack_Object.Code_Vector is
    begin
        return New_Error_Code_Vector(ERROR_CODE_NO_METHOD, LENGTH);
    end function;
        
    function  New_Error_Code_Vector_Invalid_Argment(LENGTH:integer) return MsgPack_Object.Code_Vector is
    begin
        return New_Error_Code_Vector(ERROR_CODE_INVALID_ARGMENT, LENGTH);
    end function;
        
    function  New_Error_Code_Vector_Invalid_Message(LENGTH:integer) return MsgPack_Object.Code_Vector is
    begin
        return New_Error_Code_Vector(ERROR_CODE_INVALID_MESSAGE, LENGTH);
    end function;
        
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  Is_Error_Code    (NUM:integer;CODE:MsgPack_Object.Code_Type) return boolean is
    begin
        return ((CODE.class = MsgPack_Object.CLASS_RESERVE) and
                (CODE.valid = '1'                         ) and
                (CODE.data(3 downto 0) = std_logic_vector(to_unsigned(NUM, 4))));
    end function;

    function  Is_Error_Code_Proc_Busy      (CODE:MsgPack_Object.Code_Type) return boolean is
    begin
        return Is_Error_Code(ERROR_CODE_PROC_BUSY, CODE);
    end function;
        
    function  Is_Error_Code_No_Method      (CODE:MsgPack_Object.Code_Type) return boolean is
    begin
        return Is_Error_Code(ERROR_CODE_NO_METHOD, CODE);
    end function;
        
    function  Is_Error_Code_Invalid_Argment(CODE:MsgPack_Object.Code_Type) return boolean is
    begin
        return Is_Error_Code(ERROR_CODE_INVALID_ARGMENT, CODE);
    end function;

    function  Is_Error_Code_Invalid_Message(CODE:MsgPack_Object.Code_Type) return boolean is
    begin
        return Is_Error_Code(ERROR_CODE_INVALID_MESSAGE, CODE);
    end function;
    
end MsgPack_RPC;
