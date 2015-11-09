-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_binary_memory.vhd
--!     @brief   MessagePack Object encode to binary/string memory
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
entity  MsgPack_Object_Encode_Binary_Memory is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 1;
        ADDR_BITS       :  positive := 1;
        SIZE_BITS       :  positive := 1;
        ENCODE_BINARY   :  boolean  := TRUE;
        ENCODE_STRING   :  boolean  := FALSE
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
        ADDR            : in  std_logic_vector(ADDR_BITS  -1 downto 0);
        SIZE            : in  std_logic_vector(SIZE_BITS  -1 downto 0);
        BUSY            : out std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Binary/String Data Stream Input Interface
    -------------------------------------------------------------------------------
        I_ADDR          : out std_logic_vector(ADDR_BITS  -1 downto 0);
        I_STRB          : out std_logic_vector(DATA_BITS/8-1 downto 0);
        I_LAST          : out std_logic;
        I_DATA          : in  std_logic_vector(DATA_BITS  -1 downto 0);
        I_VALID         : in  std_logic;
        I_READY         : out std_logic
    );
end MsgPack_Object_Encode_Binary_Memory;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_Binary_Stream;
use     MsgPack.PipeWork_Components.CHOPPER;
architecture RTL of MsgPack_Object_Encode_Binary_Memory is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_strb       :  std_logic_vector(DATA_BITS/8-1 downto 0);
    signal    intake_last       :  std_logic;
    signal    intake_valid      :  std_logic;
    signal    intake_ready      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    curr_addr         :  unsigned(ADDR_BITS  -1 downto 0);
    signal    next_addr         :  unsigned(ADDR_BITS  -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  CALC_WORD_WIDTH   return integer is
        variable  width  : integer;
    begin
        width := 0;
        while (2**(width+3) < DATA_BITS) loop
            width := width + 1;
        end loop;
        return width;
    end function;
    constant  WORD_WIDTH        :  integer := CALC_WORD_WIDTH;
    signal    chop_load         :  std_logic;
    signal    chop_update       :  std_logic;
    signal    word_size         :  std_logic_vector(WORD_WIDTH downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_addr, chop_update, word_size) begin
        if (chop_update = '1') then
            next_addr <= to_01(curr_addr) + to_01(unsigned(word_size));
        else
            next_addr <= curr_addr;
        end if;
    end process;
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
    I_ADDR  <= std_logic_vector(next_addr);
    I_STRB  <= intake_strb;
    I_LAST  <= intake_last;
    I_READY <= intake_ready;
    intake_valid <= I_VALID;
    -------------------------------------------------------------------------------
    -- String/Binary Data Chopper
    -------------------------------------------------------------------------------
    CHOP: CHOPPER                                   -- 
        generic map (                               -- 
            BURST           => 1                  , -- 
            MIN_PIECE       => WORD_WIDTH         , -- 
            MAX_PIECE       => WORD_WIDTH         , -- 
            MAX_SIZE        => SIZE'length        , -- 
            ADDR_BITS       => ADDR'length        , --
            SIZE_BITS       => SIZE'length        , -- 
            COUNT_BITS      => SIZE'length        , --
            PSIZE_BITS      => word_size'length   , -- 
            GEN_VALID       => 1                    -- 
        )                                           -- 
        port map(                                   -- 
            CLK             => CLK                , -- In  :
            RST             => RST                , -- In  :
            CLR             => CLR                , -- In  :
            ADDR            => ADDR               , -- In  :
            SIZE            => SIZE               , -- In  :
            SEL             => "1"                , -- In  :
            LOAD            => START              , -- In  :
            CHOP            => chop_update        , -- In  :
            COUNT           => open               , -- Out :
            NONE            => open               , -- Out :
            LAST            => intake_last        , -- Out :
            NEXT_NONE       => open               , -- Out :
            NEXT_LAST       => open               , -- Out :
            PSIZE           => word_size          , -- Out :
            NEXT_PSIZE      => open               , -- Out :
            VALID           => intake_strb        , -- Out :
            NEXT_VALID      => open                 -- Out :
        );                                          --
    chop_update <= '1' when (intake_valid = '1' and intake_ready = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STREAM: MsgPack_Object_Encode_Binary_Stream     -- 
        generic map (                               --
            CODE_WIDTH      => CODE_WIDTH         , --
            DATA_BITS       => DATA_BITS          , --
            SIZE_BITS       => SIZE_BITS          , --
            ENCODE_BINARY   => ENCODE_BINARY      , --
            ENCODE_STRING   => ENCODE_STRING      , --
            I_JUSTIFIED     => FALSE              , --
            I_BUFFERED      => TRUE                 --
        )                                           -- 
        port map (                                  -- 
        -------------------------------------------------------------------------------
        -- Clock and Reset Signals
        -------------------------------------------------------------------------------
            CLK             => CLK                , -- In  :
            RST             => RST                , -- In  :
            CLR             => CLR                , -- In  :
        -------------------------------------------------------------------------------
        -- 
        -------------------------------------------------------------------------------
            START           => START              , -- In  :
            SIZE            => SIZE               , -- In  :
            BUSY            => BUSY               , -- Out :
        -------------------------------------------------------------------------------
        -- Object Code Output Interface
        -------------------------------------------------------------------------------
            O_CODE          => O_CODE             , -- Out :
            O_LAST          => O_LAST             , -- Out :
            O_ERROR         => O_ERROR            , -- Out :
            O_VALID         => O_VALID            , -- Out :
            O_READY         => O_READY            , -- In  :
        -------------------------------------------------------------------------------
        -- Binary/String Data Stream Input Interface
        -------------------------------------------------------------------------------
            I_DATA          => I_DATA             , -- In  :
            I_STRB          => intake_strb        , -- In  :
            I_LAST          => intake_last        , -- In  :
            I_VALID         => intake_valid       , -- In  :
            I_READY         => intake_ready         -- Out :
        );
end RTL;
