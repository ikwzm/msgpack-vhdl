-----------------------------------------------------------------------------------
--!     @file    msgpack_object.vhd
--!     @brief   MessagePack Object Code Package :
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
use     ieee.numeric_std.all;
package MsgPack_Object is

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   CLASS_TYPE        is std_logic_vector(3 downto 0);
    constant  CLASS_NONE        :  CLASS_TYPE := "0000";
    constant  CLASS_BOOLEAN     :  CLASS_TYPE := "0001";
    constant  CLASS_ARRAY       :  CLASS_TYPE := "0010";
    constant  CLASS_MAP         :  CLASS_TYPE := "0011";
    constant  CLASS_UINT        :  CLASS_TYPE := "0100";
    constant  CLASS_INT         :  CLASS_TYPE := "0101";
    constant  CLASS_FLOAT       :  CLASS_TYPE := "0110";
    constant  CLASS_NIL         :  CLASS_TYPE := "0111";
    constant  CLASS_STRING_SIZE :  CLASS_TYPE := "1000";
    constant  CLASS_STRING_DATA :  CLASS_TYPE := "1001";
    constant  CLASS_BINARY_SIZE :  CLASS_TYPE := "1010";
    constant  CLASS_BINARY_DATA :  CLASS_TYPE := "1011";
    constant  CLASS_EXT_SIZE    :  CLASS_TYPE := "1100";
    constant  CLASS_EXT_DATA    :  CLASS_TYPE := "1101";
    constant  CLASS_EXT_TYPE    :  CLASS_TYPE := "1110";
    constant  CLASS_RESERVE     :  CLASS_TYPE := "1111";

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  CODE_DATA_BITS    :  integer := 32;
    constant  CODE_DATA_BYTES   :  integer := CODE_DATA_BITS/8;
    constant  CODE_STRB_BITS    :  integer := CODE_DATA_BITS/8;
    constant  CODE_DATA_NULL    :  std_logic_vector(CODE_DATA_BITS-1 downto 0)
                                := (others => '0');
    constant  CODE_STRB_NULL    :  std_logic_vector(CODE_STRB_BITS-1 downto 0)
                                := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      Code_Type         is record
                  data          :  std_logic_vector(CODE_DATA_BITS-1 downto 0);
                  strb          :  std_logic_vector(CODE_STRB_BITS-1 downto 0);
                  class         :  CLASS_TYPE;
                  complete      :  std_logic;
                  valid         :  std_logic;
    end record;
    type      Code_Vector       is array (integer range <>) of Code_Type;
    constant  CODE_NULL         :  Code_Type := (
                  data          => CODE_DATA_NULL,
                  strb          => CODE_STRB_NULL,
                  class         => CLASS_NONE    ,
                  complete      => '0'           ,
                  valid         => '0'
              );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code(
                  CLASS         :  CLASS_TYPE;
                  DATA          :  std_logic_vector;
                  STRB          :  std_logic_vector;
                  COMPLETE      :  std_logic
              )   return           Code_Type;
    function  New_Code(
                  CLASS         :  CLASS_TYPE;
                  DATA          :  std_logic_vector;
                  COMPLETE      :  std_logic
              )   return           Code_Type;
    function  New_Code(
                  CLASS         :  CLASS_TYPE;
                  DATA          :  std_logic_vector
              )   return           Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Unsigned  (DATA:integer         ;COMPLETE:std_logic:='1') return Code_Type;
    function  New_Code_Unsigned  (DATA:unsigned        ;COMPLETE:std_logic:='1') return Code_Type;
    function  New_Code_Unsigned  (DATA:std_logic_vector;COMPLETE:std_logic:='1') return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Signed    (DATA:integer         ;COMPLETE:std_logic:='1') return Code_Type;
    function  New_Code_Signed    (DATA:unsigned        ;COMPLETE:std_logic:='1') return Code_Type;
    function  New_Code_Signed    (DATA:signed          ;COMPLETE:std_logic:='1') return Code_Type;
    function  New_Code_Signed    (DATA:std_logic_vector;COMPLETE:std_logic:='1') return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Float     (DATA:std_logic_vector;COMPLETE:std_logic:='1') return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_ArraySize (SIZE:integer                                 ) return Code_Type;
    function  New_Code_ArraySize (SIZE:unsigned                                ) return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_MapSize   (SIZE:integer                                 ) return Code_Type;
    function  New_Code_MapSize   (SIZE:unsigned                                ) return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_StringSize(SIZE:integer                                 ) return Code_Type;
    function  New_Code_StringSize(SIZE:integer         ;COMPLETE:std_logic     ) return Code_Type;
    function  New_Code_StringSize(SIZE:unsigned                                ) return Code_Type;
    function  New_Code_StringSize(SIZE:unsigned        ;COMPLETE:std_logic     ) return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_StringData(DATA:std_logic_vector;COMPLETE:std_logic     ) return Code_Type;
    function  New_Code_StringData(DATA:STRING          ;COMPLETE:std_logic     ) return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_BinarySize(SIZE:integer                                 ) return Code_Type;
    function  New_Code_BinarySize(SIZE:integer         ;COMPLETE:std_logic     ) return Code_Type;
    function  New_Code_BinarySize(SIZE:unsigned                                ) return Code_Type;
    function  New_Code_BinarySize(SIZE:unsigned        ;COMPLETE:std_logic     ) return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_ExtSize   (SIZE:integer                                 ) return Code_Type;
    function  New_Code_ExtSize   (SIZE:unsigned                                ) return Code_Type;
    function  New_Code_ExtType   (DATA:std_logic_vector;COMPLETE:std_logic     ) return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Nil     return Code_Type;
    function  New_Code_True    return Code_Type;
    function  New_Code_False   return Code_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Reserve                           return Code_Type;
    function  New_Code_Reserve   (DATA:integer         ) return Code_Type;
    function  New_Code_Reserve   (DATA:unsigned        ) return Code_Type;
    function  New_Code_Reserve   (DATA:std_logic_vector) return Code_Type;

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector(
                  LENGTH        :  integer;
                  CLASS         :  CLASS_TYPE;
                  DATA          :  std_logic_vector;
                  STRB          :  std_logic_vector;
                  COMPLETE      :  std_logic
              )   return           Code_Vector;
    function  New_Code_Vector(
                  LENGTH        :  integer;
                  CLASS         :  CLASS_TYPE;
                  DATA          :  std_logic_vector;
                  COMPLETE      :  std_logic
              )   return           Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Integer   (LENGTH:integer;DATA:unsigned                   ) return Code_Vector;
    function  New_Code_Vector_Integer   (LENGTH:integer;DATA:  signed                   ) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Unsigned  (LENGTH:integer;DATA:integer                    ) return Code_Vector;
    function  New_Code_Vector_Unsigned  (LENGTH:integer;DATA:unsigned                   ) return Code_Vector;
    function  New_Code_Vector_Unsigned  (LENGTH:integer;DATA:std_logic_vector           ) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Signed    (LENGTH:integer;DATA:integer                    ) return Code_Vector;
    function  New_Code_Vector_Signed    (LENGTH:integer;DATA:signed                     ) return Code_Vector;
    function  New_Code_Vector_Signed    (LENGTH:integer;DATA:std_logic_vector           ) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Float     (LENGTH:integer;DATA:std_logic_vector           ) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_ArraySize (LENGTH:integer;SIZE:integer                    ) return Code_Vector;
    function  New_Code_Vector_ArraySize (LENGTH:integer;SIZE:unsigned                   ) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_MapSize   (LENGTH:integer;SIZE:integer                    ) return Code_Vector;
    function  New_Code_Vector_MapSize   (LENGTH:integer;SIZE:unsigned                   ) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_StringSize(LENGTH:integer;SIZE:integer                    ) return Code_Vector;
    function  New_Code_Vector_StringSize(LENGTH:integer;SIZE:integer ;COMPLETE:std_logic) return Code_Vector;
    function  New_Code_Vector_StringSize(LENGTH:integer;SIZE:unsigned                   ) return Code_Vector;
    function  New_Code_Vector_StringSize(LENGTH:integer;SIZE:unsigned;COMPLETE:std_logic) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_StringData(LENGTH:integer;DATA:std_logic_vector;COMPLETE:std_logic:='1') return Code_Vector;
    function  New_Code_Vector_StringData(LENGTH:integer;DATA:STRING          ;COMPLETE:std_logic:='1') return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_String    (LENGTH:integer;DATA:std_logic_vector;COMPLETE:std_logic:='1') return Code_Vector;
    function  New_Code_Vector_String    (LENGTH:integer;DATA:STRING          ;COMPLETE:std_logic:='1') return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_BinarySize(LENGTH:integer;SIZE:integer                    ) return Code_Vector;
    function  New_Code_Vector_BinarySize(LENGTH:integer;SIZE:integer ;COMPLETE:std_logic) return Code_Vector;
    function  New_Code_Vector_BinarySize(LENGTH:integer;SIZE:unsigned                   ) return Code_Vector;
    function  New_Code_Vector_BinarySize(LENGTH:integer;SIZE:unsigned;COMPLETE:std_logic) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_ExtSize   (LENGTH:integer;SIZE:integer                            ) return Code_Vector;
    function  New_Code_Vector_ExtSize   (LENGTH:integer;SIZE:unsigned                           ) return Code_Vector;
    function  New_Code_Vector_ExtType   (LENGTH:integer;DATA:std_logic_vector                   ) return Code_Vector;
    function  New_Code_Vector_ExtType   (LENGTH:integer;DATA:std_logic_vector;COMPLETE:std_logic) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Nil       (LENGTH:integer) return Code_Vector;
    function  New_Code_Vector_True      (LENGTH:integer) return Code_Vector;
    function  New_Code_Vector_False     (LENGTH:integer) return Code_Vector;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Reserve   (LENGTH:integer                      ) return Code_Vector;
    function  New_Code_Vector_Reserve   (LENGTH:integer;DATA:integer         ) return Code_Vector;
    function  New_Code_Vector_Reserve   (LENGTH:integer;DATA:unsigned        ) return Code_Vector;
    function  New_Code_Vector_Reserve   (LENGTH:integer;DATA:std_logic_vector) return Code_Vector;

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      Match_State_Type  is  (MATCH_IDLE_STATE               ,
                                     MATCH_BUSY_STATE               ,
                                     MATCH_DONE_FOUND_LAST_STATE    ,
                                     MATCH_DONE_FOUND_CONT_STATE    ,
                                     MATCH_BUSY_NOT_FOUND_STATE     ,
                                     MATCH_DONE_NOT_FOUND_LAST_STATE,
                                     MATCH_DONE_NOT_FOUND_CONT_STATE
                                    );
end MsgPack_Object;

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
package body MsgPack_Object is
    -------------------------------------------------------------------------------
    -- resize
    -------------------------------------------------------------------------------
    function  resize(VEC: std_logic_vector; LEN: integer) return std_logic_vector is
        variable r_vec :  std_logic_vector(       LEN-1 downto 0);
        alias    i_vec :  std_logic_vector(VEC'length-1 downto 0) is VEC;
    begin
        for i in r_vec'range loop
            if (i <= i_vec'high) then
                r_vec(i) := i_vec(i);
            else
                r_vec(i) := '0';
            end if;
        end loop;
        return r_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code
    -------------------------------------------------------------------------------
    function  New_Code(
                  CLASS     :  CLASS_TYPE;
                  DATA      :  std_logic_vector;
                  STRB      :  std_logic_vector;
                  COMPLETE  :  std_logic
              ) return         Code_Type is
        alias     i_data    :  std_logic_vector(DATA'length-1 downto 0) is DATA;
        variable  code      :  Code_Type;
    begin
        code.class := CLASS;
        code.data  := resize(DATA, CODE_DATA_BITS);
        code.strb  := resize(STRB, CODE_STRB_BITS);
        if (code.strb /= CODE_STRB_NULL) then
            code.valid    := '1';
            code.complete := COMPLETE;
        else
            code.valid    := '0';
            code.complete := '0';
        end if;
        return code;
    end function;

    function  New_Code(
                  CLASS     :  CLASS_TYPE;
                  DATA      :  std_logic_vector;
                  COMPLETE  :  std_logic
              ) return         Code_Type is
        variable  i_strb    :  std_logic_vector(CODE_STRB_BITS-1 downto 0);
        alias     i_data    :  std_logic_vector(DATA'length   -1 downto 0) is DATA;
    begin
        for i in i_strb'range loop
            if (i < (i_data'length+7)/8) then
                i_strb(i) := '1';
            else
                i_strb(i) := '0';
            end if;
        end loop;
        return New_Code(CLASS, i_data, i_strb, COMPLETE);
    end function;

    function  New_Code(
                  CLASS     :  CLASS_TYPE;
                  DATA      :  std_logic_vector
              ) return         Code_Type is
    begin
        return New_Code(CLASS, DATA, std_logic'('1'));
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_Unsigned
    -------------------------------------------------------------------------------
    function  New_Code_Unsigned  (DATA:std_logic_vector;COMPLETE:std_logic := '1') return Code_Type is
    begin
        return New_Code(CLASS_UINT, DATA, COMPLETE);
    end function;

    function  New_Code_Unsigned  (DATA:unsigned        ;COMPLETE:std_logic := '1') return Code_Type is
    begin
        return New_Code(CLASS_UINT, std_logic_vector(DATA), COMPLETE);
    end function;

    function  New_Code_Unsigned  (DATA:integer         ;COMPLETE:std_logic := '1') return Code_Type is
    begin
        return New_Code(CLASS_UINT, std_logic_vector(to_unsigned(DATA, CODE_DATA_BITS)), COMPLETE);
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_Signed
    -------------------------------------------------------------------------------
    function  New_Code_Signed    (DATA:std_logic_vector;COMPLETE:std_logic := '1') return Code_Type is
    begin
        return New_Code(CLASS_INT, DATA, COMPLETE);
    end function;

    function  New_Code_Signed    (DATA:signed          ;COMPLETE:std_logic := '1') return Code_Type is
        variable  i_strb    :  std_logic_vector(CODE_STRB_BITS-1 downto 0);
    begin
        for i in i_strb'range loop
            if (i < (DATA'length+7)/8) then
                i_strb(i) := '1';
            else
                i_strb(i) := '0';
            end if;
        end loop;
        return New_Code(CLASS_INT, std_logic_vector(resize(DATA, CODE_DATA_BITS)), i_strb, COMPLETE);
    end function;

    function  New_Code_Signed    (DATA:unsigned        ;COMPLETE:std_logic := '1') return Code_Type is
        variable  i_strb    :  std_logic_vector(CODE_STRB_BITS-1 downto 0);
    begin
        for i in i_strb'range loop
            if (i < (DATA'length+7)/8) then
                i_strb(i) := '1';
            else
                i_strb(i) := '0';
            end if;
        end loop;
        return New_Code(CLASS_INT, std_logic_vector(resize(DATA, CODE_DATA_BITS)), i_strb, COMPLETE);
    end function;

    function  New_Code_Signed    (DATA:integer         ;COMPLETE:std_logic := '1') return Code_Type is
    begin
        return New_Code(CLASS_INT, std_logic_vector(to_signed(DATA, CODE_DATA_BITS)), COMPLETE);
    end function;
    
    -------------------------------------------------------------------------------
    -- New_Code_Float
    -------------------------------------------------------------------------------
    function  New_Code_Float     (DATA:std_logic_vector;COMPLETE:std_logic := '1') return Code_Type is
    begin
        return New_Code(CLASS_FLOAT, DATA, COMPLETE);
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_ArraySize
    -------------------------------------------------------------------------------
    function  New_Code_ArraySize (SIZE:unsigned) return Code_Type is
    begin
        return New_Code(CLASS_ARRAY, std_logic_vector(SIZE), '1');
    end function;
    
    function  New_Code_ArraySize (SIZE:integer ) return Code_Type is
    begin
        return New_Code(CLASS_ARRAY, std_logic_vector(to_unsigned(SIZE, CODE_DATA_BITS)), '1');
    end function;
        
    -------------------------------------------------------------------------------
    -- New_Code_MapSize
    -------------------------------------------------------------------------------
    function  New_Code_MapSize   (SIZE:unsigned) return Code_Type is
    begin
        return New_Code(CLASS_MAP, std_logic_vector(SIZE), '1');
    end function;
    
    function  New_Code_MapSize   (SIZE:integer ) return Code_Type is
    begin
        return New_Code(CLASS_MAP, std_logic_vector(to_unsigned(SIZE, CODE_DATA_BITS)), '1');
    end function;
        
    -------------------------------------------------------------------------------
    -- New_Code_StringSize
    -------------------------------------------------------------------------------
    function  New_Code_StringSize(SIZE:unsigned;COMPLETE:std_logic) return Code_Type is
    begin
        return New_Code(CLASS_STRING_SIZE, std_logic_vector(SIZE), COMPLETE);
    end function;
    
    function  New_Code_StringSize(SIZE:unsigned               ) return Code_Type is
    begin
        if (SIZE = 0) then
            return New_Code_StringSize(SIZE, '1');
        else
            return New_Code_StringSize(SIZE, '0');
        end if;
    end function;
    
    function  New_Code_StringSize(SIZE:integer; COMPLETE:std_logic) return Code_Type is
    begin
        return New_Code_StringSize(to_unsigned(SIZE, CODE_DATA_BITS), COMPLETE);
    end function;
        
    function  New_Code_StringSize(SIZE:integer                ) return Code_Type is
    begin
        if (SIZE = 0) then
            return New_Code_StringSize(SIZE, '1');
        else
            return New_Code_StringSize(SIZE, '0');
        end if;
    end function;
        
    -------------------------------------------------------------------------------
    -- New_Code_StringData
    -------------------------------------------------------------------------------
    function  New_Code_StringData(DATA:std_logic_vector;COMPLETE:std_logic       ) return Code_Type is
    begin
        return New_Code(CLASS_STRING_DATA, DATA, COMPLETE);
    end function;        
    function  New_Code_StringData(DATA:STRING          ;COMPLETE:std_logic       ) return Code_Type is
        alias     i_str   :  STRING(1 to DATA'length) is DATA;
        variable  i_data  :  std_logic_vector(8*DATA'length-1 downto 0);
    begin
        for i in i_str'range loop
            i_data(8*(i)-1 downto 8*(i-1)) := std_logic_vector(to_unsigned(CHARACTER'pos(i_str(i)),8));
        end loop;
        return New_Code_StringData(i_data, complete);
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_BinarySize
    -------------------------------------------------------------------------------
    function  New_Code_BinarySize(SIZE:unsigned;COMPLETE:std_logic) return Code_Type is
    begin
        return New_Code(CLASS_BINARY_SIZE, std_logic_vector(SIZE), COMPLETE);
    end function;
    
    function  New_Code_BinarySize(SIZE:unsigned               ) return Code_Type is
    begin
        if (SIZE = 0) then
            return New_Code_BinarySize(SIZE, '1');
        else
            return New_Code_BinarySize(SIZE, '0');
        end if;
    end function;
    
    function  New_Code_BinarySize(SIZE:integer ;COMPLETE:std_logic) return Code_Type is
    begin
        return New_Code_BinarySize(to_unsigned(SIZE, CODE_DATA_BITS), COMPLETE);
    end function;

    function  New_Code_BinarySize(SIZE:integer         ) return Code_Type is
    begin
        if (SIZE = 0) then
            return New_Code_BinarySize(SIZE, '1');
        else
            return New_Code_BinarySize(SIZE, '0');
        end if;
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_ExtSize
    -------------------------------------------------------------------------------
    function  New_Code_ExtSize   (SIZE:unsigned        ) return Code_Type is
    begin
        return New_Code(CLASS_EXT_SIZE, std_logic_vector(SIZE), '0');
    end function;
    
    function  New_Code_ExtSize   (SIZE:integer         ) return Code_Type is
    begin
        return New_Code(CLASS_EXT_SIZE, std_logic_vector(to_unsigned(SIZE, CODE_DATA_BITS)), '0');
    end function;
    
    -------------------------------------------------------------------------------
    -- New_Code_ExtType
    -------------------------------------------------------------------------------
    function  New_Code_ExtType  (DATA:std_logic_vector;COMPLETE:std_logic) return Code_Type is
    begin
        return New_Code(CLASS_EXT_TYPE, resize(DATA, 8), COMPLETE);
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_Nil
    -------------------------------------------------------------------------------
    function  New_Code_Nil     return Code_Type is begin
        return New_Code(CLASS_NIL    , std_logic_vector'("00000000"));
    end function;
    
    -------------------------------------------------------------------------------
    -- New_Code_True
    -------------------------------------------------------------------------------
    function  New_Code_True    return Code_Type is begin
        return New_Code(CLASS_BOOLEAN, std_logic_vector'("00000001"));
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_False
    -------------------------------------------------------------------------------
    function  New_Code_False   return Code_Type is begin
        return New_Code(CLASS_BOOLEAN, std_logic_vector'("00000000"));
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_Reserve
    -------------------------------------------------------------------------------
    function  New_Code_Reserve   (DATA:std_logic_vector) return Code_Type is begin
        return New_Code(CLASS_RESERVE, DATA);
    end function;
    function  New_Code_Reserve   (DATA:unsigned        ) return Code_Type is begin
        return New_Code_Reserve(std_logic_vector(DATA));
    end function;
    function  New_Code_Reserve   (DATA:integer         ) return Code_Type is begin
        return New_Code_Reserve(to_unsigned(DATA, CODE_DATA_BITS));
    end function;
    function  New_Code_Reserve                           return Code_Type is begin
        return New_Code_Reserve(0);
    end function;

    -------------------------------------------------------------------------------
    -- New_Code_Vector
    -------------------------------------------------------------------------------
    function  New_Code_Vector(
                  LENGTH    :  integer;
                  CLASS     :  CLASS_TYPE;
                  DATA      :  std_logic_vector;
                  STRB      :  std_logic_vector;
                  COMPLETE  :  std_logic
              ) return         Code_Vector is
        variable  code_vec  :  Code_Vector     (               LENGTH-1 downto 0);
        variable  i_data    :  std_logic_vector(CODE_DATA_BITS*LENGTH-1 downto 0);
        variable  i_strb    :  std_logic_vector(CODE_STRB_BITS*LENGTH-1 downto 0);
        variable  t_data    :  std_logic_vector(CODE_DATA_BITS       -1 downto 0);
        variable  t_strb    :  std_logic_vector(CODE_STRB_BITS       -1 downto 0);
        variable  t_complete:  boolean;
        variable  t_valid   :  boolean;
    begin
        i_data     := resize(DATA, CODE_DATA_BITS*LENGTH);
        i_strb     := resize(STRB, CODE_STRB_BITS*LENGTH);
        t_complete := (COMPLETE = '1');

        for i in LENGTH-1 downto 0 loop
            t_data  := i_data(CODE_DATA_BITS*(i+1)-1 downto CODE_DATA_BITS*i);
            t_strb  := i_strb(CODE_STRB_BITS*(i+1)-1 downto CODE_STRB_BITS*i);
            t_valid := (t_strb /= CODE_STRB_NULL);
            
            for n in 0 to CODE_STRB_BITS-1 loop
                if (t_strb(n) = '1') then
                    code_vec(i).data(8*(n+1)-1 downto 8*n) := t_data(8*(n+1)-1 downto 8*n);
                else
                    code_vec(i).data(8*(n+1)-1 downto 8*n) := (8*(n+1)-1 downto 8*n => '0');
                end if;
            end loop;

            code_vec(i).strb := t_strb;
            
            if (t_valid) then
                code_vec(i).valid := '1';
                code_vec(i).class := CLASS;
            else
                code_vec(i).valid := '0';
                code_vec(i).class := CLASS_NONE;
            end if;

            if (t_complete = TRUE and t_valid = TRUE) then
                code_vec(i).complete  := '1';
                t_complete            := FALSE;
            else
                code_vec(i).complete  := '0';
            end if;

        end loop;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector
    -------------------------------------------------------------------------------
    function  New_Code_Vector(
                  LENGTH    :  integer;
                  CLASS     :  CLASS_TYPE;
                  DATA      :  std_logic_vector;
                  COMPLETE  :  std_logic
              ) return         Code_Vector is
        variable  i_strb    :  std_logic_vector((DATA'length+7)/8-1 downto 0);
    begin
        for i in i_strb'range loop
            if (i < (DATA'length+7)/8) then
                i_strb(i) := '1';
            else
                i_strb(i) := '0';
            end if;
        end loop;
        return New_Code_Vector(LENGTH, CLASS, DATA, i_strb, COMPLETE);
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_Unsigned
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Unsigned  (LENGTH:integer;DATA:integer) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_Unsigned(DATA,'1');
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_Unsigned  (LENGTH:integer;DATA:unsigned) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
        alias    i_data   :  unsigned(DATA'length-1 downto 0) is DATA;
    begin
        if (i_data'high > 32) then
            if (LENGTH >= 2) then
                code_vec(0) := New_Code_Unsigned(i_data(i_data'high downto 32), '0');
                code_vec(1) := New_Code_Unsigned(i_data(         31 downto  0), '1');
            else
                assert FALSE report "New_Code_Vector_Unsigned argument bit width is to large." severity FAILURE;
            end if;
            if (LENGTH >  2) then
                code_vec(LENGTH-1 downto 2) := (LENGTH-1 downto 2 => CODE_NULL);
            end if;
        else
            if (LENGTH >= 1) then
                code_vec(0) := New_Code_Unsigned(i_data, '1');
            end if;
            if (LENGTH >  1) then
                code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
            end if;
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_Unsigned  (LENGTH:integer;DATA:std_logic_vector) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
        alias    i_data   :  std_logic_vector(DATA'length-1 downto 0) is DATA;
    begin
        if (i_data'high > 32) then
            if (LENGTH >= 2) then
                code_vec(0) := New_Code_Unsigned(i_data(i_data'high downto 32), '0');
                code_vec(1) := New_Code_Unsigned(i_data(         31 downto  0), '1');
            else
                assert FALSE report "New_Code_Vector_Unsigned argument bit width is to large." severity FAILURE;
            end if;
            if (LENGTH >  2) then
                code_vec(LENGTH-1 downto 2) := (LENGTH-1 downto 2 => CODE_NULL);
            end if;
        else
            if (LENGTH >= 1) then
                code_vec(0) := New_Code_Unsigned(i_data, '1');
            end if;
            if (LENGTH >  1) then
                code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
            end if;
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_Signed
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Signed    (LENGTH:integer;DATA:integer) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_Signed(DATA,'1');
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_Signed    (LENGTH:integer;DATA:signed) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
        alias    i_data   :  signed(DATA'length-1 downto 0) is DATA;
        variable d_data   :  signed(63 downto 0);
    begin
        if (i_data'high > 32) then
            if (LENGTH >= 2) then
                d_data := resize(i_data, 64);
                code_vec(0) := New_Code_Signed(d_data(63 downto 32), '0');
                code_vec(1) := New_Code_Signed(d_data(31 downto  0), '1');
            else
                assert FALSE report "New_Code_Vector_Signed argument bit width is to large." severity FAILURE;
            end if;
            if (LENGTH >  2) then
                code_vec(LENGTH-1 downto 2) := (LENGTH-1 downto 2 => CODE_NULL);
            end if;
        else
            if (LENGTH >= 1) then
                code_vec(0) := New_Code_Signed(i_data, '1');
            end if;
            if (LENGTH >  1) then
                code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
            end if;
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_Signed    (LENGTH:integer;DATA:std_logic_vector) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
        alias    i_data   :  std_logic_vector(DATA'length-1 downto 0) is DATA;
        variable d_data   :  std_logic_vector(63 downto 0);
    begin
        if (i_data'high > 32) then
            if (LENGTH >= 2) then
                d_data := std_logic_vector(resize(signed(i_data), 64));
                code_vec(0) := New_Code_Signed(d_data(63 downto 32), '0');
                code_vec(1) := New_Code_Signed(d_data(31 downto  0), '1');
            else
                assert FALSE report "New_Code_Vector_Signed argument bit width is to large." severity FAILURE;
            end if;
            if (LENGTH >  2) then
                code_vec(LENGTH-1 downto 2) := (LENGTH-1 downto 2 => CODE_NULL);
            end if;
        else
            if (LENGTH >= 1) then
                code_vec(0) := New_Code_Signed(i_data, '1');
            end if;
            if (LENGTH >  1) then
                code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
            end if;
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_Integer
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Integer   (LENGTH:integer;DATA:signed                     ) return Code_Vector is
        variable use_long :  boolean;
        variable i_data   :  std_logic_vector(DATA'length-1 downto 0);
    begin
        i_data := std_logic_vector(DATA);
        if (i_data'length > CODE_DATA_BITS) then
            use_long := FALSE;
            for pos in i_data'high downto CODE_DATA_BITS loop
                if (i_data(pos) /= i_data(CODE_DATA_BITS-1)) then
                    use_long := TRUE;
                end if;
            end loop;
            if (i_data(i_data'high) = '1') then
                if (use_long) then
                    return New_Code_Vector_Signed(  LENGTH, i_data);
                else
                    return New_Code_Vector_Signed(  LENGTH, i_data(CODE_DATA_BITS-1 downto 0));
                end if;
            else
                if (use_long) then
                    return New_Code_Vector_Unsigned(LENGTH, i_data);
                else
                    return New_Code_Vector_Unsigned(LENGTH, i_data(CODE_DATA_BITS-1 downto 0));
                end if;
            end if;
        else
            if (i_data(i_data'high) = '1') then
                return New_Code_Vector_Signed  (LENGTH, i_data);
            else
                return New_Code_Vector_Unsigned(LENGTH, i_data);
            end if;
        end if;
    end function;
    function  New_Code_Vector_Integer   (LENGTH:integer;DATA:unsigned                   ) return Code_Vector is
        variable use_long :  boolean;
        alias    i_data   :  unsigned(DATA'length-1 downto 0) is DATA;
    begin
        if (i_data'length > CODE_DATA_BITS) then
            use_long := FALSE;
            for pos in i_data'high downto CODE_DATA_BITS loop
                if (i_data(pos) /= '0') then
                    use_long := TRUE;
                end if;
            end loop;
            if (use_long) then
                return New_Code_Vector_Unsigned(LENGTH, i_data);
            else
                return New_Code_Vector_Unsigned(LENGTH, i_data(CODE_DATA_BITS-1 downto 0));
            end if;
        else
                return New_Code_Vector_Unsigned(LENGTH, i_data);
        end if;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_Float
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Float     (LENGTH:integer;DATA:std_logic_vector) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
        alias    i_data   :  std_logic_vector(DATA'length-1 downto 0) is DATA;
    begin
        if (i_data'high > 32) then
            if (LENGTH >= 2) then
                code_vec(0) := New_Code_Float(i_data(63 downto 32), '0');
                code_vec(1) := New_Code_Float(i_data(31 downto  0), '1');
            else
                assert FALSE report "New_Code_Vector_Float argument bit width is to large." severity FAILURE;
            end if;
            if (LENGTH >  2) then
                code_vec(LENGTH-1 downto 2) := (LENGTH-1 downto 2 => CODE_NULL);
            end if;
        else
            if (LENGTH >= 1) then
                code_vec(0) := New_Code_Float(i_data, '1');
            end if;
            if (LENGTH >  1) then
                code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
            end if;
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_ArraySize
    -------------------------------------------------------------------------------
    function  New_Code_Vector_ArraySize (LENGTH:integer;SIZE:integer ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_ArraySize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_ArraySize (LENGTH:integer;SIZE:unsigned) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_ArraySize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_MapSize
    -------------------------------------------------------------------------------
    function  New_Code_Vector_MapSize   (LENGTH:integer;SIZE:integer ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_MapSize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_MapSize   (LENGTH:integer;SIZE:unsigned) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_MapSize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_StringSize
    -------------------------------------------------------------------------------
    function  New_Code_Vector_StringSize(LENGTH:integer;SIZE:integer                   ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_StringSize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_StringSize(LENGTH:integer;SIZE:integer;COMPLETE:std_logic) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_StringSize(SIZE,COMPLETE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_StringSize(LENGTH:integer;SIZE:unsigned                  ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_StringSize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_StringSize(LENGTH:integer;SIZE:unsigned;COMPLETE:std_logic) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_StringSize(SIZE,COMPLETE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_StringData
    -------------------------------------------------------------------------------
    function  New_Code_Vector_StringData(LENGTH:integer;DATA:std_logic_vector;COMPLETE:std_logic := '1') return Code_Vector is
    begin
        return New_Code_Vector(LENGTH, CLASS_STRING_DATA, DATA, COMPLETE);
    end function;
    function  New_Code_Vector_StringData(LENGTH:integer;DATA:STRING          ;COMPLETE:std_logic := '1') return Code_Vector is
        alias     i_str   :  STRING(1 to DATA'length) is DATA;
        variable  i_data  :  std_logic_vector(8*DATA'length-1 downto 0);
    begin
        for i in i_str'range loop
            i_data(8*(i)-1 downto 8*(i-1)) := std_logic_vector(to_unsigned(CHARACTER'pos(i_str(i)),8));
        end loop;
        return New_Code_Vector_StringData(LENGTH, i_data, COMPLETE);
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_String
    -------------------------------------------------------------------------------
    function  New_Code_Vector_String    (LENGTH:integer;DATA:std_logic_vector;COMPLETE:std_logic := '1') return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_StringSize((DATA'length+7)/8);
        code_vec(LENGTH-1 downto 1) := New_Code_Vector_StringData(LENGTH-1, DATA, COMPLETE);
        return code_vec;
    end function;
    function  New_Code_Vector_String    (LENGTH:integer;DATA:STRING          ;COMPLETE:std_logic := '1') return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_StringSize(DATA'length);
        code_vec(LENGTH-1 downto 1) := New_Code_Vector_StringData(LENGTH-1, DATA, COMPLETE);
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_BinarySize
    -------------------------------------------------------------------------------
    function  New_Code_Vector_BinarySize(LENGTH:integer;SIZE:integer                    ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_BinarySize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_BinarySize(LENGTH:integer;SIZE:integer ;COMPLETE:std_logic) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_BinarySize(SIZE,COMPLETE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_BinarySize(LENGTH:integer;SIZE:unsigned                   ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_BinarySize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_BinarySize(LENGTH:integer;SIZE:unsigned;COMPLETE:std_logic) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_BinarySize(SIZE,COMPLETE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_ExtSize
    -------------------------------------------------------------------------------
    function  New_Code_Vector_ExtSize   (LENGTH:integer;SIZE:integer                           ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_ExtSize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_ExtSize   (LENGTH:integer;SIZE:unsigned                           ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_ExtSize(SIZE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_ExtType   (LENGTH:integer;DATA:std_logic_vector                   ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_ExtType(DATA, '0');
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_ExtType   (LENGTH:integer;DATA:std_logic_vector;COMPLETE:std_logic) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_ExtType(DATA,COMPLETE);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_Nil
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Nil       (LENGTH:integer) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_Nil;
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_True
    -------------------------------------------------------------------------------
    function  New_Code_Vector_True      (LENGTH:integer) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_True;
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_False
    -------------------------------------------------------------------------------
    function  New_Code_Vector_False     (LENGTH:integer) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_False;
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    -- New_Code_Vector_Reserve
    -------------------------------------------------------------------------------
    function  New_Code_Vector_Reserve   (LENGTH:integer;DATA:std_logic_vector) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_Reserve(DATA);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_Reserve   (LENGTH:integer;DATA:unsigned        ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_Reserve(DATA);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_Reserve   (LENGTH:integer;DATA:integer         ) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_Reserve(DATA);
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;
    function  New_Code_Vector_Reserve   (LENGTH:integer) return Code_Vector is
        variable code_vec :  Code_Vector(LENGTH-1 downto 0);
    begin
        code_vec(0) := New_Code_Reserve;
        if (LENGTH > 1) then
            code_vec(LENGTH-1 downto 1) := (LENGTH-1 downto 1 => CODE_NULL);
        end if;
        return code_vec;
    end function;

end MsgPack_Object;
