-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_get_value.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) Get Value Module :
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
entity  MsgPack_KVMap_Get_Value is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        STORE_SIZE      :  positive := 8;
        MATCH_PHASE     :  positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_KEY_CODE      : in  MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        I_KEY_LAST      : in  std_logic;
        I_KEY_VALID     : in  std_logic;
        I_KEY_ERROR     : out std_logic;
        I_KEY_DONE      : out std_logic;
        I_KEY_SHIFT     : out std_logic_vector(                     CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_KEY_CODE      : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        O_KEY_VALID     : out std_logic;
        O_KEY_LAST      : out std_logic;
        O_KEY_ERROR     : out std_logic;
        O_KEY_READY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Value Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_VAL_CODE      : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        O_VAL_VALID     : out std_logic;
        O_VAL_LAST      : out std_logic;
        O_VAL_ERROR     : out std_logic;
        O_VAL_READY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Compare Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector(                    MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        MATCH_OK        : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        MATCH_NOT       : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        MATCH_SHIFT     : in  std_logic_vector(          STORE_SIZE*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_VALID     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_CODE      : in  MsgPack_Object.Code_Vector(STORE_SIZE*CODE_WIDTH-1 downto 0);
        VALUE_LAST      : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_ERROR     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_READY     : out std_logic_vector(          STORE_SIZE           -1 downto 0)
    );
end MsgPack_KVMap_Get_Value;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Key_Match_Aggregator;
architecture RTL of MsgPack_KVMap_Get_Value is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    key_match_valid   :  std_logic;
    signal    key_match_state   :  MsgPack_Object.Match_State_Type;
    signal    key_match_shift   :  std_logic_vector(CODE_WIDTH-1 downto 0);
    signal    key_match_select  :  std_logic_vector(STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE        is (MATCH_KEY_STATE, GET_VALUE_STATE, UNDEF_KEY_STATE);
    signal    curr_state        :  STATE_TYPE;
    signal    requ_state        :  STATE_TYPE;
    signal    next_state        :  STATE_TYPE;
    signal    value_select      :  std_logic_vector(STORE_SIZE-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    KEY_MATCH_AGGREGATE: MsgPack_KVMap_Key_Match_Aggregator -- 
        generic map (                                    -- 
            CODE_WIDTH    => CODE_WIDTH                , --
            MATCH_NUM     => STORE_SIZE                , -- 
            MATCH_PHASE   => MATCH_REQ'length            -- 
        )                                                -- 
        port map (                                       -- 
            CLK           => CLK                       , -- In  :
            RST           => RST                       , -- In  :
            CLR           => CLR                       , -- In  :
            I_KEY_VALID   => key_match_valid           , -- In  :
            I_KEY_CODE    => I_KEY_CODE                , -- In  :
            I_KEY_LAST    => I_KEY_LAST                , -- In  :
            I_KEY_SHIFT   => key_match_shift           , -- Out :
            O_KEY_VALID   => O_KEY_VALID               , -- Out :
            O_KEY_CODE    => O_KEY_CODE                , -- Out :
            O_KEY_LAST    => O_KEY_LAST                , -- Out :
            O_KEY_READY   => O_KEY_READY               , -- In  :
            MATCH_REQ     => MATCH_REQ                 , -- Out :
            MATCH_OK      => MATCH_OK                  , -- In  :
            MATCH_NOT     => MATCH_NOT                 , -- In  :
            MATCH_SHIFT   => MATCH_SHIFT               , -- In  :
            MATCH_SEL     => key_match_select          , -- Out :
            MATCH_STATE   => key_match_state             -- Out :
        );                                               --
    MATCH_CODE    <= I_KEY_CODE;                         -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_state, key_match_state, key_match_select) begin
        case curr_state is
            when MATCH_KEY_STATE =>
                case key_match_state is
                    when MsgPack_Object.MATCH_DONE_FOUND_CONT_STATE |
                         MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE =>
                        VALUE_START <= key_match_select;
                        requ_state  <= GET_VALUE_STATE;
                    when MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE |
                         MsgPack_Object.MATCH_DONE_NOT_FOUND_LAST_STATE =>
                        VALUE_START <= (others => '0');
                        requ_state  <= UNDEF_KEY_STATE;
                    when others =>
                        VALUE_START <= (others => '0');
                        requ_state  <= MATCH_KEY_STATE;
                end case;
            when others =>
                        VALUE_START <= (others => '0');
                        requ_state  <= curr_state;
        end case;
    end process;
    key_match_valid <= I_KEY_VALID     when (curr_state = MATCH_KEY_STATE) else '0';
    I_KEY_SHIFT     <= key_match_shift when (curr_state = MATCH_KEY_STATE) else (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state   <= MATCH_KEY_STATE;
                value_select <= (others => '0');
                I_KEY_ERROR  <= '0';
                I_KEY_DONE   <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state   <= MATCH_KEY_STATE;
                value_select <= (others => '0');
                I_KEY_ERROR  <= '0';
                I_KEY_DONE   <= '0';
            else
                case curr_state is
                    when MATCH_KEY_STATE =>
                        curr_state <= requ_state;
                        if (requ_state = GET_VALUE_STATE) then
                            value_select <= key_match_select;
                        else
                            value_select <= (others => '0');
                        end if;
                        case key_match_state is
                            when MsgPack_Object.MATCH_DONE_FOUND_CONT_STATE     |
                                 MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE     |
                                 MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE |
                                 MsgPack_Object.MATCH_DONE_NOT_FOUND_LAST_STATE =>
                                I_KEY_ERROR <= '0';
                                I_KEY_DONE  <= '1';
                            when others =>
                                I_KEY_ERROR <= '0';
                                I_KEY_DONE  <= '0';
                        end case;
                    when others => 
                        curr_state <= next_state;
                        if (next_state = MATCH_KEY_STATE) then
                            value_select <= (others => '0');
                        end if;
                        I_KEY_ERROR <= '0';
                        I_KEY_DONE  <= '0';
                end case;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_state, value_select,
             VALUE_VALID, VALUE_CODE, VALUE_LAST, VALUE_ERROR, O_VAL_READY)
        variable  val_valid     :  std_logic;
        variable  val_last      :  std_logic;
        variable  val_error     :  std_logic;
        variable  val_code      :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    begin
        val_valid := '0';
        val_last  := '0';
        val_error := '0';
        val_code  := (others => MsgPack_Object.CODE_NULL);
        for i in 0 to STORE_SIZE-1 loop
            if (value_select(i) = '1') then
                 val_valid := val_valid or VALUE_VALID(i);
                 val_last  := val_last  or VALUE_LAST (i);
                 val_error := val_error or VALUE_ERROR(i);
                 for n in 0 to CODE_WIDTH-1 loop
                     val_code(n).data     := val_code(n).data     or VALUE_CODE(CODE_WIDTH*i+n).data;
                     val_code(n).strb     := val_code(n).strb     or VALUE_CODE(CODE_WIDTH*i+n).strb;
                     val_code(n).class    := val_code(n).class    or VALUE_CODE(CODE_WIDTH*i+n).class;
                     val_code(n).complete := val_code(n).complete or VALUE_CODE(CODE_WIDTH*i+n).complete;
                     val_code(n).valid    := val_code(n).valid    or VALUE_CODE(CODE_WIDTH*i+n).valid;
                 end loop;
            end if;
        end loop;
        case curr_state is
            when GET_VALUE_STATE =>
                O_VAL_VALID <= val_valid;
                O_VAL_LAST  <= val_last;
                O_VAL_ERROR <= val_error;
                O_VAL_CODE  <= val_code;
                if (O_VAL_READY = '1') then
                    VALUE_READY <= value_select;
                else
                    VALUE_READY <= (others => '0');
                end if;
                if (val_valid = '1' and val_last = '1' and O_VAL_READY = '1') then
                    next_state <= MATCH_KEY_STATE;
                else
                    next_state <= GET_VALUE_STATE;
                end if;
            when UNDEF_KEY_STATE =>
                O_VAL_VALID <= '1';
                O_VAL_LAST  <= '1';
                O_VAL_ERROR <= '1';
                O_VAL_CODE  <= MsgPack_Object.New_Code_Vector_Nil(CODE_WIDTH);
                VALUE_READY <= (others => '0');
                if (O_VAL_READY = '1') then
                    next_state <= MATCH_KEY_STATE;
                else
                    next_state <= UNDEF_KEY_STATE;
                end if;
            when others =>
                O_VAL_VALID <= '0';
                O_VAL_LAST  <= '0';
                O_VAL_ERROR <= '0';
                O_VAL_CODE  <= val_code;
                VALUE_READY <= (others => '0');
                next_state  <= curr_state;
        end case;
    end process;
end RTL;
