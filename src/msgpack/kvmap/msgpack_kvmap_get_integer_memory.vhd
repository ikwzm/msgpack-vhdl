-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_get_integer_memory.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) Get Integer Memory Module :
--!     @version 0.2.0
--!     @date    2015/11/9
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
entity  MsgPack_KVMap_Get_Integer_Memory is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        KEY             :  STRING;
        CODE_WIDTH      :  positive := 1;
        MATCH_PHASE     :  positive := 8;
        ADDR_BITS       :  positive := 32;
        SIZE_BITS       :  positive := 32;  
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack Key Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Input Interface
    -------------------------------------------------------------------------------
        ADDR            : out std_logic_vector( ADDR_BITS-1 downto 0);
        VALUE           : in  std_logic_vector(VALUE_BITS-1 downto 0);
        VALID           : in  std_logic;
        READY           : out std_logic
    );
end  MsgPack_KVMap_Get_Integer_Memory;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_Integer_Memory;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Key_Compare;
architecture RTL of MsgPack_KVMap_Get_Integer_Memory is
    signal    start    :  std_logic;
    signal    busy     :  std_logic;
    constant  size     :  std_logic_vector(SIZE_BITS-1 downto 0)
                       := std_logic_vector(to_unsigned(2**ADDR_BITS, SIZE_BITS));
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    MATCH: MsgPack_KVMap_Key_Compare             -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , -- 
            I_MAX_PHASE     => MATCH_PHASE     , --
            KEYWORD         => KEY               --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- 
            RST             => RST             , -- 
            CLR             => CLR             , -- 
            I_CODE          => MATCH_CODE      , -- 
            I_REQ_PHASE     => MATCH_REQ       , -- 
            MATCH           => MATCH_OK        , -- 
            MISMATCH        => MATCH_NOT       , -- 
            SHIFT           => MATCH_SHIFT       -- 
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (I_VALID, I_CODE) begin
        if (I_VALID = '1' and I_CODE(0).valid = '1') then
            if    (I_CODE(0).class = MsgPack_Object.CLASS_NIL) then
                start   <= '1';
                I_ERROR <= '0';
                I_DONE  <= '1';
                I_SHIFT <= (0 => '1', others => '0');
            else
                start   <= '0';
                I_ERROR <= '1';
                I_DONE  <= '1';
                I_SHIFT <= (others => '0');
            end if;
        else
                start   <= '0';
                I_ERROR <= '0';
                I_DONE  <= '0';
                I_SHIFT <= (others => '0');
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ENCODE: MsgPack_Object_Encode_Integer_Memory -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , --
            ADDR_BITS       => ADDR_BITS       , --
            SIZE_BITS       => SIZE_BITS       , --
            VALUE_BITS      => VALUE_BITS      , --
            VALUE_SIGN      => VALUE_SIGN      , --
            QUEUE_SIZE      => 0                 -- 
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            START           => start           , -- In  :
            ADDR            => std_logic_vector(to_unsigned(0, ADDR_BITS)), 
            SIZE            => size            , -- In  :
            BUSY            => busy            , -- In  :
            I_ADDR          => ADDR            , -- Out :
            I_VALUE         => VALUE           , -- In  :
            I_VALID         => VALID           , -- In  :
            I_READY         => READY           , -- Out :
            O_CODE          => O_CODE          , -- Out :
            O_LAST          => O_LAST          , -- Out :
            O_ERROR         => O_ERROR         , -- Out :
            O_VALID         => O_VALID         , -- Out :
            O_READY         => O_READY           -- In  :
        );                                       --
end RTL;
