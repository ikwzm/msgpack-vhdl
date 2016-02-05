-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_integer_memory.vhd
--!     @brief   MessagePack Object encode to integer memory
--!     @version 0.1.0
--!     @date    2015/10/25
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
entity  MsgPack_Object_Encode_Integer_Memory is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        ADDR_BITS       :  positive := 32;
        SIZE_BITS       :  positive := 32;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE;
        QUEUE_SIZE      :  integer  := 0
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        START           : in  std_logic;
        ADDR            : in  std_logic_vector( ADDR_BITS-1 downto 0);
        SIZE            : in  std_logic_vector( SIZE_BITS-1 downto 0);
        BUSY            : out std_logic;
    -------------------------------------------------------------------------------
    -- Integer Value Input Interface
    -------------------------------------------------------------------------------
        I_ADDR          : out std_logic_vector( ADDR_BITS-1 downto 0);
        I_VALUE         : in  std_logic_vector(VALUE_BITS-1 downto 0);
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- Array Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end MsgPack_Object_Encode_Integer_Memory;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_Integer_Stream;
architecture RTL of MsgPack_Object_Encode_Integer_Memory is
    signal    curr_addr         :  unsigned(ADDR_BITS-1 downto 0);
    signal    next_addr         :  unsigned(ADDR_BITS-1 downto 0);
    signal    intake_ready      :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STREAM: MsgPack_Object_Encode_Integer_Stream     -- 
        ---------------------------------------------------------------------------
        -- Generic Parameters
        ---------------------------------------------------------------------------
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH          , --
            SIZE_BITS       => SIZE_BITS           , --
            VALUE_BITS      => VALUE_BITS          , --
            VALUE_SIGN      => VALUE_SIGN          , --
            QUEUE_SIZE      => QUEUE_SIZE            --
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
            START           => START               , -- In  :
            SIZE            => SIZE                , -- In  :
            BUSY            => BUSY                , -- Out :
        ---------------------------------------------------------------------------
        -- Integer Value Input Interface
        ---------------------------------------------------------------------------
            I_VALUE         => I_VALUE             , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_READY         => intake_ready        , -- Out :
        ---------------------------------------------------------------------------
        -- Array Object Encode Output Interface
        ---------------------------------------------------------------------------
            O_CODE          => O_CODE              , -- Out :
            O_LAST          => O_LAST              , -- Out :
            O_ERROR         => O_ERROR             , -- Out :
            O_VALID         => O_VALID             , -- Out :
            O_READY         => O_READY               -- In  :
        );                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_addr <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_addr <= (others => '0');
            elsif (START = '1') then
                curr_addr <= unsigned(ADDR);
            else
                curr_addr <= next_addr;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    I_READY <= intake_ready;
    I_ADDR  <= std_logic_vector(next_addr);
    process (curr_addr, I_VALID, intake_ready) begin
        if (I_VALID = '1' and intake_ready = '1') then
            next_addr <= curr_addr + 1;
        else
            next_addr <= curr_addr;
        end if;
    end process;
end RTL;
