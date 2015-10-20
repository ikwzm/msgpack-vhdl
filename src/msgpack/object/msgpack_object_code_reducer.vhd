-----------------------------------------------------------------------------------
--!     @file    msgpack_object_code_reducer.vhd
--!     @brief   MessagePack Object Code Reducer :
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
library MsgPack;
use     MsgPack.MsgPack_Object;
entity  MsgPack_Object_Code_Reducer is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        I_WIDTH         : positive := 1;
        O_WIDTH         : positive := 1;
        O_VALID_SIZE    : integer range 0 to 64 := 1;
        QUEUE_SIZE      : integer := 0
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Control and Status Signals 
    -------------------------------------------------------------------------------
        DONE            : in  std_logic := '0';
        BUSY            : out std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Input Interface
    -------------------------------------------------------------------------------
        I_ENABLE        : in  std_logic := '1';
        I_CODE          : in  MsgPack_Object.Code_Vector(I_WIDTH-1 downto 0);
        I_DONE          : in  std_logic := '0';
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_ENABLE        : in  std_logic := '1';
        O_CODE          : out MsgPack_Object.Code_Vector(O_WIDTH-1 downto 0);
        O_DONE          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
        O_SHIFT         : in  std_logic_vector(O_WIDTH-1 downto 0) := (others => '0')
    );
end MsgPack_Object_Code_Reducer;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.PipeWork_Components.REDUCER;
architecture RTL of MsgPack_Object_Code_Reducer is
    constant   WORD_LO       :  integer := 0;
    constant   WORD_DATA_LO  :  integer := WORD_LO;
    constant   WORD_DATA_HI  :  integer := WORD_DATA_LO + MsgPack_Object.CODE_DATA_BITS    - 1;
    constant   WORD_STRB_LO  :  integer := WORD_DATA_HI + 1;
    constant   WORD_STRB_HI  :  integer := WORD_STRB_LO + MsgPack_Object.CODE_STRB_BITS    - 1;
    constant   WORD_TYPE_LO  :  integer := WORD_STRB_HI + 1;
    constant   WORD_TYPE_HI  :  integer := WORD_TYPE_LO + MsgPack_Object.CLASS_TYPE'length - 1;
    constant   WORD_COMP_POS :  integer := WORD_TYPE_HI + 1;
    constant   WORD_HI       :  integer := WORD_COMP_POS;
    constant   WORD_BITS     :  integer := WORD_HI - WORD_LO + 1;
    constant   offset        :  std_logic_vector(O_WIDTH          -1 downto 0) := (others => '0');
    signal     i_word        :  std_logic_vector(I_WIDTH*WORD_BITS-1 downto 0);
    signal     i_strb        :  std_logic_vector(I_WIDTH          -1 downto 0);
    signal     o_word        :  std_logic_vector(O_WIDTH*WORD_BITS-1 downto 0);
    signal     o_strb        :  std_logic_vector(O_WIDTH          -1 downto 0);
    signal     t_valid       :  std_logic_vector(O_WIDTH          -1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (I_CODE)begin
        for i in 0 to I_WIDTH-1 loop
            i_word(WORD_BITS*i+WORD_DATA_HI downto WORD_BITS*i+WORD_DATA_LO) <= I_CODE(i).data;
            i_word(WORD_BITS*i+WORD_TYPE_HI downto WORD_BITS*i+WORD_TYPE_LO) <= I_CODE(i).class;
            i_word(WORD_BITS*i+WORD_STRB_HI downto WORD_BITS*i+WORD_STRB_LO) <= I_CODE(i).strb;
            i_word(WORD_BITS*i+WORD_COMP_POS                               ) <= I_CODE(i).complete;
            i_strb(i)                                                        <= I_CODE(i).valid;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    QUEUE: REDUCER                              -- 
        generic map (                           -- 
            WORD_BITS       => WORD_BITS      , -- 
            STRB_BITS       => 1              , -- 
            I_WIDTH         => I_WIDTH        , -- 
            O_WIDTH         => O_WIDTH        , -- 
            QUEUE_SIZE      => QUEUE_SIZE     , -- 
            VALID_MIN       => 0              , -- 
            VALID_MAX       => O_WIDTH-1      , -- 
            O_VAL_SIZE      => O_VALID_SIZE   , -- 
            O_SHIFT_MIN     => 0              , --
            O_SHIFT_MAX     => O_WIDTH-1      , --
            I_JUSTIFIED     => 0              , -- 
            FLUSH_ENABLE    => 0                -- 
        )                                       -- 
        port map (                              --
            CLK             => CLK            , -- In  :
            RST             => RST            , -- In  :
            CLR             => CLR            , -- In  :
            START           => '0'            , -- In  :
            OFFSET          => offset         , -- In  :
            DONE            => DONE           , -- In  :
            FLUSH           => '0'            , -- In  :
            BUSY            => BUSY           , -- Out :
            VALID           => t_valid        , -- Out :
            I_ENABLE        => I_ENABLE       , -- In  :
            I_STRB          => i_strb         , -- In  :
            I_DATA          => i_word         , -- In  :
            I_DONE          => I_DONE         , -- In  :
            I_FLUSH         => '0'            , -- In  :
            I_VAL           => I_VALID        , -- In  :
            I_RDY           => I_READY        , -- Out :
            O_ENABLE        => O_ENABLE       , -- In  :
            O_DATA          => o_word         , -- Out :
            O_STRB          => o_strb         , -- Out :
            O_DONE          => O_DONE         , -- Out :
            O_FLUSH         => open           , -- Out :
            O_VAL           => O_VALID        , -- Out :
            O_RDY           => O_READY        , -- In  :
            O_SHIFT         => O_SHIFT          -- In  :
    );                                          -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process(o_word, o_strb, t_valid) begin
        for i in 0 to O_WIDTH-1 loop
            O_CODE(i).data     <= o_word(WORD_BITS*i+WORD_DATA_HI downto WORD_BITS*i+WORD_DATA_LO);
            O_CODE(i).strb     <= o_word(WORD_BITS*i+WORD_STRB_HI downto WORD_BITS*i+WORD_STRB_LO);
            O_CODE(i).class    <= o_word(WORD_BITS*i+WORD_TYPE_HI downto WORD_BITS*i+WORD_TYPE_LO);
            O_CODE(i).complete <= o_word(WORD_BITS*i+WORD_COMP_POS);
            O_CODE(i).valid    <= t_valid(i);
        end loop;
    end process;
end RTL;
