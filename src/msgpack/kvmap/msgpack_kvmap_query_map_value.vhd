-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_query_map_value.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) Query Map Value Module :
--!     @version 0.2.0
--!     @date    2016/5/17
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
entity  MsgPack_KVMap_Query_Map_Value is
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
    -- Value Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_VAL_START     : in  std_logic;
        I_VAL_ABORT     : in  std_logic;
        I_VAL_CODE      : in  MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        I_VAL_LAST      : in  std_logic;
        I_VAL_VALID     : in  std_logic;
        I_VAL_ERROR     : out std_logic;
        I_VAL_DONE      : out std_logic;
        I_VAL_SHIFT     : out std_logic_vector(                     CODE_WIDTH-1 downto 0);
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
    -- Parameter Object Decode Output Interface
    -------------------------------------------------------------------------------
        PARAM_START     : out std_logic_vector(          STORE_SIZE           -1 downto 0);
        PARAM_VALID     : out std_logic_vector(          STORE_SIZE           -1 downto 0);
        PARAM_CODE      : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        PARAM_LAST      : out std_logic;
        PARAM_ERROR     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        PARAM_DONE      : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        PARAM_SHIFT     : in  std_logic_vector(          STORE_SIZE*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        VALUE_VALID     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_CODE      : in  MsgPack_Object.Code_Vector(STORE_SIZE*CODE_WIDTH-1 downto 0);
        VALUE_LAST      : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_ERROR     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_READY     : out std_logic_vector(          STORE_SIZE           -1 downto 0)
    );
end MsgPack_KVMap_Query_Map_Value;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Dispatcher;
architecture RTL of MsgPack_KVMap_Query_Map_Value is
    signal    req_select    :  std_logic_vector(STORE_SIZE-1 downto 0);
    signal    req_start     :  std_logic;
    signal    req_error     :  std_logic;
    signal    req_abort     :  std_logic;
    signal    busy          :  std_logic;
    signal    value_select  :  std_logic_vector(STORE_SIZE-1 downto 0);
    type      STATE_TYPE    is (IDLE_STATE, GET_VALUE_STATE, UNDEF_KEY_STATE);
    signal    curr_state    :  STATE_TYPE;
    signal    next_state    :  STATE_TYPE;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DISPATCH: MsgPack_KVMap_Dispatcher           -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , --
            STORE_SIZE      => STORE_SIZE      , --
            MATCH_PHASE     => MATCH_PHASE       --
        )                                        -- 
        port map (                               -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
        ---------------------------------------------------------------------------
        -- Key Object Decode Input Interface
        ---------------------------------------------------------------------------
            I_KEY_CODE      => I_KEY_CODE      , -- In  :
            I_KEY_LAST      => I_KEY_LAST      , -- In  :
            I_KEY_VALID     => I_KEY_VALID     , -- In  :
            I_KEY_ERROR     => I_KEY_ERROR     , -- Out :
            I_KEY_DONE      => I_KEY_DONE      , -- Out :
            I_KEY_SHIFT     => I_KEY_SHIFT     , -- Out :
        ---------------------------------------------------------------------------
        -- Value Object Decode Input Interface
        ---------------------------------------------------------------------------
            I_VAL_START     => I_VAL_START     , -- In  :
            I_VAL_ABORT     => I_VAL_ABORT     , -- In  :
            I_VAL_CODE      => I_VAL_CODE      , -- In  :
            I_VAL_LAST      => I_VAL_LAST      , -- In  :
            I_VAL_VALID     => I_VAL_VALID     , -- In  :
            I_VAL_ERROR     => I_VAL_ERROR     , -- Out :
            I_VAL_DONE      => I_VAL_DONE      , -- Out :
            I_VAL_SHIFT     => I_VAL_SHIFT     , -- Out :
        ---------------------------------------------------------------------------
        -- Key Object Encode Output Interface
        ---------------------------------------------------------------------------
            O_KEY_CODE      => O_KEY_CODE      , -- Out :
            O_KEY_VALID     => O_KEY_VALID     , -- Out :
            O_KEY_LAST      => O_KEY_LAST      , -- Out :
            O_KEY_ERROR     => O_KEY_ERROR     , -- Out :
            O_KEY_READY     => O_KEY_READY     , -- In  :
        ---------------------------------------------------------------------------
        -- Key Object Compare Interface
        ---------------------------------------------------------------------------
            MATCH_REQ       => MATCH_REQ       , -- Out :
            MATCH_CODE      => MATCH_CODE      , -- Out :
            MATCH_OK        => MATCH_OK        , -- In  :
            MATCH_NOT       => MATCH_NOT       , -- In  :
            MATCH_SHIFT     => MATCH_SHIFT     , -- In  :
        ---------------------------------------------------------------------------
        -- Value Object Decode Output Interface
        ---------------------------------------------------------------------------
            VALUE_START     => PARAM_START     , -- Out :
            VALUE_VALID     => PARAM_VALID     , -- Out :
            VALUE_CODE      => PARAM_CODE      , -- Out :
            VALUE_LAST      => PARAM_LAST      , -- Out :
            VALUE_ERROR     => PARAM_ERROR     , -- In  :
            VALUE_DONE      => PARAM_DONE      , -- In  :
            VALUE_SHIFT     => PARAM_SHIFT     , -- In  :
        ---------------------------------------------------------------------------
        -- Dispatch Control/Status Interface
        ---------------------------------------------------------------------------
            DISPATCH_SELECT => req_select      , -- Out :
            DISPATCH_START  => req_start       , -- Out :
            DISPATCH_ERROR  => req_error       , -- Out :
            DISPATCH_ABORT  => req_abort       , -- Out :
            DISPATCH_BUSY   => busy              -- In  :
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state   <= IDLE_STATE;
                value_select <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state   <= IDLE_STATE;
                value_select <= (others => '0');
            else
                case curr_state is
                    when IDLE_STATE =>
                        if    (req_start = '1') then
                            curr_state   <= GET_VALUE_STATE;
                            value_select <= req_select;
                        elsif (req_error = '1') then
                            curr_state   <= UNDEF_KEY_STATE;
                            value_select <= (others => '0');
                        else
                            curr_state   <= IDLE_STATE;
                            value_select <= (others => '0');
                        end if;
                    when GET_VALUE_STATE =>
                        curr_state <= next_state;
                        if (next_state /= GET_VALUE_STATE) then
                            value_select <= (others => '0');
                        end if;
                    when UNDEF_KEY_STATE =>
                        curr_state <= next_state;
                        value_select <= (others => '0');
                    when others =>
                        curr_state   <= IDLE_STATE;
                        value_select <= (others => '0');
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
                    next_state <= IDLE_STATE;
                    busy       <= '0';
                else
                    next_state <= GET_VALUE_STATE;
                    busy       <= '1';
                end if;
            when UNDEF_KEY_STATE =>
                O_VAL_VALID <= '1';
                O_VAL_LAST  <= '1';
                O_VAL_ERROR <= '1';
                O_VAL_CODE  <= MsgPack_Object.New_Code_Vector_Nil(CODE_WIDTH);
                VALUE_READY <= (others => '0');
                if (O_VAL_READY = '1') then
                    next_state <= IDLE_STATE;
                    busy       <= '0';
                else
                    next_state <= UNDEF_KEY_STATE;
                    busy       <= '1';
                end if;
            when others =>
                O_VAL_VALID <= '0';
                O_VAL_LAST  <= '0';
                O_VAL_ERROR <= '0';
                O_VAL_CODE  <= val_code;
                VALUE_READY <= (others => '0');
                next_state  <= curr_state;
                busy        <= '0';
        end case;
    end process;
end RTL;
