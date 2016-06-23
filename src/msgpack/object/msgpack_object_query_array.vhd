-----------------------------------------------------------------------------------
--!     @file    msgpack_object_query_array.vhd
--!     @brief   MessagePack Object Query Array Module :
--!     @version 0.2.0
--!     @date    2016/6/23
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
entity  MsgPack_Object_Query_Array is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        ADDR_BITS       :  integer  := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Array Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Value Map Encode Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_VALID         : out std_logic;
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Parameter Object Decode Output Interface
    -------------------------------------------------------------------------------
        PARAM_START     : out std_logic;
        PARAM_ADDR      : out std_logic_vector(           ADDR_BITS-1 downto 0);
        PARAM_VALID     : out std_logic;
        PARAM_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        PARAM_LAST      : out std_logic;
        PARAM_ERROR     : in  std_logic;
        PARAM_DONE      : in  std_logic;
        PARAM_SHIFT     : in  std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        VALUE_VALID     : in  std_logic;
        VALUE_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        VALUE_LAST      : in  std_logic;
        VALUE_ERROR     : in  std_logic;
        VALUE_READY     : out std_logic
    );
end MsgPack_Object_Query_Array;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Map;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_Map;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Integer;
architecture RTL of MsgPack_Object_Query_Array is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  SIZE_BITS         :  integer := 32;
    signal    map_enable        :  std_logic;
    signal    map_start         :  std_logic;
    signal    map_size          :  std_logic_vector          ( SIZE_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_key_code   :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    intake_key_valid  :  std_logic_vector          (           1 downto 0);
    signal    intake_key_ready  :  std_logic;
    signal    intake_key_last   :  std_logic;
    signal    intake_key_error  :  std_logic;
    signal    intake_key_done   :  std_logic;
    signal    intake_key_shift  :  std_logic_vector          (CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    outlet_key_code   :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    outlet_key_valid  :  std_logic;
    signal    outlet_key_ready  :  std_logic;
    signal    outlet_key_last   :  std_logic;
    signal    outlet_key_error  :  std_logic;
    signal    outlet_key_done   :  std_logic;
    signal    outlet_key_shift  :  std_logic_vector          (CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    decode_addr_value :  std_logic_vector          ( ADDR_BITS-1 downto 0);
    signal    decode_addr_valid :  std_logic;
    constant  decode_addr_ready :  std_logic := '1';
    constant  DECODE_ADDR_ENA64 :  boolean   := (ADDR_BITS >= 64);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE_MAP: MsgPack_Object_Decode_Map            -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH            --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
        ---------------------------------------------------------------------------
        -- Control/Status Signals
        ---------------------------------------------------------------------------
            ENABLE          => map_enable          , -- In  :
            BUSY            => open                , -- Out :
            READY           => open                , -- Out :
        ---------------------------------------------------------------------------
        -- MessagePack Object Code Input Interface
        ---------------------------------------------------------------------------
            I_CODE          => I_CODE              , -- In  :
            I_LAST          => I_LAST              , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_ERROR         => I_ERROR             , -- Out :
            I_DONE          => I_DONE              , -- Out :
            I_SHIFT         => I_SHIFT             , -- Out :
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            MAP_START       => map_start           , -- Out :
            MAP_SIZE        => map_size            , -- Out :
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            KEY_START       => open                , -- Out :
            KEY_VALID       => intake_key_valid(0) , -- Out :
            KEY_CODE        => intake_key_code     , -- Out :
            KEY_LAST        => intake_key_last     , -- Out :
            KEY_ERROR       => intake_key_error    , -- In  :
            KEY_DONE        => intake_key_done     , -- In  :
            KEY_SHIFT       => intake_key_shift    , -- In  :
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            VALUE_START     => PARAM_START         , -- Out :
            VALUE_ABORT     => open                , -- Out :
            VALUE_VALID     => PARAM_VALID         , -- Out :
            VALUE_CODE      => PARAM_CODE          , -- Out :
            VALUE_LAST      => PARAM_LAST          , -- Out :
            VALUE_ERROR     => PARAM_ERROR         , -- In  :
            VALUE_DONE      => PARAM_DONE          , -- In  :
            VALUE_SHIFT     => PARAM_SHIFT           -- In  :
        );                                           --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    KEY_QUEUE: block
        signal intake_valid    :  std_logic;
        signal intake_complete :  std_logic;
    begin
        outlet_key_code  <= intake_key_code;
        outlet_key_error <= '0';
        intake_key_ready <= outlet_key_ready;
        process(intake_key_code, intake_key_last)
            variable  i_code_valid    :  std_logic_vector(CODE_WIDTH-1 downto 0);
            variable  i_code_complete :  std_logic_vector(CODE_WIDTH-1 downto 0);
            constant  VALID_ALL_0     :  std_logic_vector(CODE_WIDTH-1 downto 0) := (others => '0');
        begin
            for i in 0 to CODE_WIDTH-1 loop
                i_code_valid   (i) := intake_key_code(i).valid;
                i_code_complete(i) := intake_key_code(i).complete;
            end loop;
            if (intake_key_last = '1') or
               ((i_code_valid and i_code_complete) /= VALID_ALL_0) then
                intake_complete <= '1';
                intake_valid    <= i_code_valid(i_code_valid'low );
            else
                intake_complete <= '0';
                intake_valid    <= i_code_valid(i_code_valid'high);
            end if;
        end process;
        outlet_key_valid <= '1' when (intake_valid    = '1' and intake_key_valid(0) = '1') else '0';
        outlet_key_last  <= '1' when (intake_complete = '1' and intake_key_valid(0) = '1') else '0';
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ENCODE_MAP: MsgPack_Object_Encode_Map            -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH          , --
            SIZE_BITS       => SIZE_BITS             -- 
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            START           => map_start           , -- In  :
            SIZE            => map_size            , -- In  :
            BUSY            => open                , -- Out :
            READY           => map_enable          , -- Out :
        ---------------------------------------------------------------------------
        -- Key Object Encode Input Interface
        ---------------------------------------------------------------------------
            I_KEY_CODE      => outlet_key_code     , -- In  :
            I_KEY_LAST      => outlet_key_last     , -- In  :
            I_KEY_ERROR     => outlet_key_error    , -- In  :
            I_KEY_VALID     => outlet_key_valid    , -- In  :
            I_KEY_READY     => outlet_key_ready    , -- Out :
        ---------------------------------------------------------------------------
        -- Value Object Encode Input Interface
        ---------------------------------------------------------------------------
            I_VAL_CODE      => VALUE_CODE          , -- In  :
            I_VAL_LAST      => VALUE_LAST          , -- In  :
            I_VAL_ERROR     => VALUE_ERROR         , -- In  :
            I_VAL_VALID     => VALUE_VALID         , -- In  :
            I_VAL_READY     => VALUE_READY         , -- Out :
        ---------------------------------------------------------------------------
        -- Map Object Encode Output Interface
        ---------------------------------------------------------------------------
            O_MAP_CODE      => O_CODE              , -- Out :
            O_MAP_LAST      => O_LAST              , -- Out :
            O_MAP_ERROR     => O_ERROR             , -- Out :
            O_MAP_VALID     => O_VALID             , -- Out :
            O_MAP_READY     => O_READY               -- In  :
    );                                               -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE_ADDR: MsgPack_Object_Decode_Integer       -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH          , -- 
            VALUE_BITS      => ADDR_BITS           , -- 
            VALUE_SIGN      => FALSE               , -- 
            QUEUE_SIZE      => 0                   , -- 
            CHECK_RANGE     => TRUE                , -- 
            ENABLE64        => DECODE_ADDR_ENA64     -- 
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
        ---------------------------------------------------------------------------
        -- MessagePack Object Code Input Interface
        ---------------------------------------------------------------------------
            I_CODE          => intake_key_code     , -- In  :
            I_LAST          => intake_key_last     , -- In  :
            I_VALID         => intake_key_valid(1) , -- In  :
            I_ERROR         => intake_key_error    , -- Out :
            I_DONE          => intake_key_done     , -- Out :
            I_SHIFT         => intake_key_shift    , -- Out :
        ---------------------------------------------------------------------------
        -- Integer Value Output Interface
        ---------------------------------------------------------------------------
            O_VALUE         => decode_addr_value   , -- Out :
            O_SIGN          => open                , -- Out :
            O_LAST          => open                , -- Out :
            O_VALID         => decode_addr_valid   , -- Out :
            O_READY         => decode_addr_ready     -- In  :
        );
    intake_key_valid(1) <= '1' when (intake_key_valid(0) = '1' and intake_key_ready = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ADDR: process (CLK, RST) begin
        if (RST = '1') then
                PARAM_ADDR <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                PARAM_ADDR <= (others => '0');
            elsif (decode_addr_valid = '1' and decode_addr_ready = '1') then
                PARAM_ADDR <= decode_addr_value;
            end if;
        end if;
    end process;
end RTL;
