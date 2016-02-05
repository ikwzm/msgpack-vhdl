-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_integer_memory.vhd
--!     @brief   MessagePack Object decode to integer memory
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
entity  MsgPack_Object_Decode_Integer_Memory is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        ADDR_BITS       :  positive := 8;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE;
        QUEUE_SIZE      :  integer  := 0;
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
    -- MessagePack Object Code Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_ADDR          : in  std_logic_vector( ADDR_BITS-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Data and Address Output
    -------------------------------------------------------------------------------
        O_START         : out std_logic;
        O_VALUE         : out std_logic_vector(VALUE_BITS-1 downto 0);
        O_ADDR          : out std_logic_vector( ADDR_BITS-1 downto 0);
        O_SIGN          : out std_logic;
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end  MsgPack_Object_Decode_Integer_Memory;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Integer_Stream;
architecture RTL of MsgPack_Object_Decode_Integer_Memory is
    signal    start         :  std_logic;
    signal    curr_addr     :  std_logic_vector(ADDR_BITS-1 downto 0);
    signal    outlet_valid  :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STREAM: MsgPack_Object_Decode_Integer_Stream
        ---------------------------------------------------------------------------
        -- Generic Parameters
        ---------------------------------------------------------------------------
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH          , -- 
            VALUE_BITS      => VALUE_BITS          , -- 
            VALUE_SIGN      => VALUE_SIGN          , -- 
            QUEUE_SIZE      => QUEUE_SIZE          , -- 
            CHECK_RANGE     => CHECK_RANGE         , -- 
            ENABLE64        => ENABLE64              -- 
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
            I_CODE          => I_CODE              , -- In  :
            I_LAST          => I_LAST              , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_ERROR         => I_ERROR             , -- Out :
            I_DONE          => I_DONE              , -- Out :
            I_SHIFT         => I_SHIFT             , -- Out :
        ---------------------------------------------------------------------------
        -- Integer Value Data and Address Output
        ---------------------------------------------------------------------------
            O_START         => start               , -- Out :
            O_VALUE         => O_VALUE             , -- Out :
            O_SIGN          => O_SIGN              , -- Out :
            O_LAST          => O_LAST              , -- Out :
            O_VALID         => outlet_valid        , -- Out :
            O_READY         => O_READY               -- In  :
        );                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O_START <= start;
    O_VALID <= outlet_valid;
    O_ADDR  <= curr_addr;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_addr <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if    (CLR = '1') then
                curr_addr <= (others => '0');
            elsif (start = '1') then
                curr_addr <= I_ADDR;
            elsif (outlet_valid = '1' and O_READY = '1') then
                curr_addr <= std_logic_vector(unsigned(curr_addr) + 1);
            end if;
        end if;
    end process;
end RTL;
