-----------------------------------------------------------------------------------
--!     @file    msgpack_object_code_compare.vhd
--!     @brief   MessagePack Object Code Compare Module :
--!     @version 0.2.0
--!     @date    2016/6/24
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2012-2016 Ichiro Kawazome
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
entity  MsgPack_Object_Code_Compare is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        C_WIDTH         : positive := 1;
        I_WIDTH         : positive := 1;
        I_MAX_PHASE     : positive := 1
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
        I_CODE          : in  MsgPack_Object.Code_Vector(I_WIDTH-1 downto 0);
        I_REQ_PHASE     : in  std_logic_vector(I_MAX_PHASE-1 downto 0);
    -------------------------------------------------------------------------------
    -- Comparison Object Code Interface
    -------------------------------------------------------------------------------
        C_CODE          : in  MsgPack_Object.Code_Vector(C_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Compare Result Output 
    -------------------------------------------------------------------------------
        MATCH           : out std_logic;
        MISMATCH        : out std_logic;
        SHIFT           : out std_logic_vector(I_WIDTH-1 downto 0)
    );
end MsgPack_Object_Code_Compare;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Code_Compare is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  LAST_PHASE        :  integer := (C_WIDTH+I_WIDTH-1)/I_WIDTH - 1;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   SHIFT_TYPE        is std_logic_vector(I_WIDTH-1 downto 0);
    subtype   CCODE_TYPE        is MsgPack_Object.Code_Vector(I_WIDTH-1 downto 0);
    type      SHIFT_VECTOR      is array (integer range <>) of SHIFT_TYPE;
    type      CCODE_VECTOR      is array (integer range <>) of CCODE_TYPE;
    signal    comp_code_vec     :  CCODE_VECTOR(LAST_PHASE downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure COMPARE_CODE(
                  I_CODE        :  in  MsgPack_Object.Code_Type;
                  C_CODE        :  in  MsgPack_Object.Code_Type;
                  MATCH         :  out std_logic;
                  MISMATCH      :  out std_logic;
                  UNRELATED     :  out std_logic;
                  PENDING       :  out std_logic
    ) is
    begin
        if    (I_CODE.valid = '1' and C_CODE.valid = '1') then
            case C_CODE.class is
                when MsgPack_Object.CLASS_NIL | MsgPack_Object.CLASS_RESERVE =>
                    if (I_CODE.class = C_CODE.class) then
                        MATCH    := '1';
                        MISMATCH := '0';
                    else
                        MATCH    := '0';
                        MISMATCH := '1';
                    end if;
                when MsgPack_Object.CLASS_BOOLEAN =>
                    if (I_CODE.class   = C_CODE.class) and
                       (I_CODE.data(0) = C_CODE.data(0)) then
                        MATCH    := '1';
                        MISMATCH := '0';
                    else
                        MATCH    := '0';
                        MISMATCH := '1';
                    end if;
                when MsgPack_Object.CLASS_EXT_TYPE =>
                    if (I_CODE.class            = C_CODE.class           ) and
                       (I_CODE.complete         = C_CODE.complete        ) and 
                       (I_CODE.data(7 downto 0) = C_CODE.data(7 downto 0)) then
                        MATCH    := '1';
                        MISMATCH := '0';
                    else
                        MATCH    := '0';
                        MISMATCH := '1';
                    end if;
                when MsgPack_Object.CLASS_STRING_DATA |
                     MsgPack_Object.CLASS_BINARY_DATA |
                     MsgPack_Object.CLASS_EXT_DATA    =>
                    if (I_CODE.class    = C_CODE.class   ) and
                       (I_CODE.complete = C_CODE.complete) and 
                       (I_CODE.strb     = C_CODE.strb    ) then
                        MATCH    := '1';
                        MISMATCH := '0';
                        for i in 0 to MsgPack_Object.CODE_STRB_BITS-1 loop
                            if (I_CODE.strb(i) = '1') and
                               (I_CODE.data(8*(i+1)-1 downto 8*i) /= C_CODE.data(8*(i+1)-1 downto 8*i)) then
                                MATCH    := '0';
                                MISMATCH := '1';
                            end if;
                        end loop;
                    else
                        MATCH    := '0';
                        MISMATCH := '1';
                    end if;
                when others =>
                    if (I_CODE.class    = C_CODE.class   ) and
                       (I_CODE.complete = C_CODE.complete) and 
                       (I_CODE.data     = C_CODE.data    ) then
                        MATCH    := '1';
                        MISMATCH := '0';
                    else
                        MATCH    := '0';
                        MISMATCH := '1';
                    end if;
            end case;
            UNRELATED := '0';
            PENDING   := '0';
        elsif (I_CODE.valid = '0' and C_CODE.valid = '1') then
            MATCH     := '0';
            MISMATCH  := '0';
            UNRELATED := '0';
            PENDING   := '1';
        else
            MATCH     := '0';
            MISMATCH  := '0';
            UNRELATED := '1';
            PENDING   := '0';
        end if;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure COMPARE_CODE_VECTER(
                  I_CODE        :  in  MsgPack_Object.Code_Vector(I_WIDTH-1 downto 0);
                  C_CODE        :  in  MsgPack_Object.Code_Vector(I_WIDTH-1 downto 0);
                  SHIFT         :  out SHIFT_TYPE;
                  MATCH         :  out std_logic;
                  MISMATCH      :  out std_logic
    ) is
        variable  match_vec     :      std_logic_vector(I_WIDTH-1 downto 0);
        variable  mismatch_vec  :      std_logic_vector(I_WIDTH-1 downto 0);
        variable  unrelated_vec :      std_logic_vector(I_WIDTH-1 downto 0);
        variable  pending_vec   :      std_logic_vector(I_WIDTH-1 downto 0);
        constant  ALL_1         :      std_logic_vector(I_WIDTH-1 downto 0) := (others => '1');
        constant  ALL_0         :      std_logic_vector(I_WIDTH-1 downto 0) := (others => '0');
    begin
        for i in 0 to I_WIDTH-1 loop
            COMPARE_CODE(
                  I_CODE        => I_CODE       (i),
                  C_CODE        => C_CODE       (i),
                  MATCH         => match_vec    (i),
                  MISMATCH      => mismatch_vec (i),
                  UNRELATED     => unrelated_vec(i),
                  PENDING       => pending_vec  (i)
            );
        end loop;
        if  (match_vec /= ALL_0) and
            ((match_vec or unrelated_vec) = ALL_1) then
            SHIFT    := match_vec;
            MATCH    := '1';
        else
            SHIFT    := (others => '0');
            MATCH    := '0';
        end if;
        if (mismatch_vec /= ALL_0) then
            MISMATCH := '1';
        else
            MISMATCH := '0';
        end if;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    ack_match    :  std_logic;
    signal    ack_mismatch :  std_logic;
    signal    ack_shift    :  std_logic_vector(I_WIDTH-1 downto 0);
    signal    mismatched   :  boolean;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (C_CODE) begin
        for phase in 0 to LAST_PHASE loop
            for word_pos in 0 to I_WIDTH-1 loop
                if (phase*I_WIDTH+word_pos <= C_CODE'high) then
                    comp_code_vec(phase)(word_pos) <= C_CODE(phase*I_WIDTH+word_pos);
                else
                    comp_code_vec(phase)(word_pos) <= MsgPack_Object.CODE_NULL;
                end if;
            end loop;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (I_CODE, I_REQ_PHASE, comp_code_vec, mismatched)
        variable  comp_shift     :  SHIFT_VECTOR    (I_MAX_PHASE-1 downto 0);
        variable  comp_match     :  std_logic_vector(I_MAX_PHASE-1 downto 0);
        variable  comp_mismatch  :  std_logic_vector(I_MAX_PHASE-1 downto 0);
        variable  temp_shift     :  SHIFT_VECTOR    (I_MAX_PHASE-1 downto 0);
        variable  temp_match     :  std_logic_vector(I_MAX_PHASE-1 downto 0);
        variable  temp_mismatch  :  std_logic_vector(I_MAX_PHASE-1 downto 0);
        variable  phase_shift    :  SHIFT_TYPE;
        variable  phase_match    :  std_logic;
        variable  phase_mismatch :  std_logic;
    begin
        for i in 0 to I_MAX_PHASE-1 loop
            if (i <= LAST_PHASE) then
                COMPARE_CODE_VECTER(               -- 
                    I_CODE   => I_CODE          ,  -- In  :
                    C_CODE   => comp_code_vec(i),  -- In  :
                    SHIFT    => comp_shift   (i),  -- Out :
                    MATCH    => comp_match   (i),  -- Out :
                    MISMATCH => comp_mismatch(i)   -- Out :
                );
            else
                comp_match   (i) := '0';
                comp_mismatch(i) := '0';
                comp_shift   (i) := (others => '0');
            end if;
        end loop;
        for i in 0 to I_MAX_PHASE-1 loop
            if (i > 0 and mismatched) or
               (i > LAST_PHASE      ) then
                temp_match   (i) := '0';
                temp_mismatch(i) := '1';
                temp_shift   (i) := (others => '0');
            else
                temp_match   (i) := comp_match   (i);
                temp_mismatch(i) := comp_mismatch(i);
                temp_shift   (i) := comp_shift   (i);
            end if;
        end loop;
        phase_shift    := (others => '0');
        phase_match    := '0';
        phase_mismatch := '0';
        for i in 0 to I_MAX_PHASE-1 loop
            if (I_REQ_PHASE(i) = '1' and i = LAST_PHASE) then
                phase_match    := phase_match    or temp_match(i);
                phase_shift    := phase_shift    or temp_shift(i);
            end if;
            if (I_REQ_PHASE(i) = '1') then
                phase_mismatch := phase_mismatch or temp_mismatch(i);
            end if;
        end loop;
        ack_shift    <= phase_shift;
        ack_match    <= phase_match;
        ack_mismatch <= phase_mismatch;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                mismatched <= FALSE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                mismatched <= FALSE;
            elsif (I_REQ_PHASE(0) = '1') then
                mismatched <= (ack_mismatch = '1');
            else
                mismatched <= (ack_mismatch = '1' or mismatched);
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    MATCH    <= ack_match;
    MISMATCH <= ack_mismatch;
    SHIFT    <= ack_shift;
end RTL;
