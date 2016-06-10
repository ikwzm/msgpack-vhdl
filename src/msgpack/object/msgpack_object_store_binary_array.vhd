-----------------------------------------------------------------------------------
--!     @file    msgpack_object_store_binary_array.vhd
--!     @brief   MessagePack Object Store Binary/String Array Module :
--!     @version 0.2.0
--!     @date    2016/6/10
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
entity  MsgPack_Object_Store_Binary_Array is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 4;
        ADDR_BITS       :  integer  := 8;
        SIZE_BITS       :  integer  := MsgPack_Object.CODE_DATA_BITS;
        DECODE_BINARY   :  boolean  := TRUE;
        DECODE_STRING   :  boolean  := FALSE
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
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Data and Address Output
    -------------------------------------------------------------------------------
        START           : out std_logic;
        BUSY            : out std_logic;
        SIZE            : out std_logic_vector(SIZE_BITS  -1 downto 0);
        ADDR            : out std_logic_vector(ADDR_BITS  -1 downto 0);
        DATA            : out std_logic_vector(DATA_BITS  -1 downto 0);
        STRB            : out std_logic_vector(DATA_BITS/8-1 downto 0);
        LAST            : out std_logic;
        VALID           : out std_logic;
        READY           : in  std_logic
    );
end  MsgPack_Object_Store_Binary_Array;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Binary_Array;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Store_Array;
architecture RTL of MsgPack_Object_Store_Binary_Array is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    param_code    :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    param_addr    :  std_logic_vector          ( ADDR_BITS-1 downto 0);
    signal    param_valid   :  std_logic;
    signal    param_last    :  std_logic;
    signal    param_error   :  std_logic;
    signal    param_done    :  std_logic;
    signal    param_shift   :  std_logic_vector          (CODE_WIDTH-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STORE_ARRAY: MsgPack_Object_Store_Array      -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , -- 
            ADDR_BITS       => ADDR_BITS         -- 
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            I_CODE          => I_CODE          , -- In  :
            I_LAST          => I_LAST          , -- In  :
            I_VALID         => I_VALID         , -- In  :
            I_ERROR         => I_ERROR         , -- Out :
            I_DONE          => I_DONE          , -- Out :
            I_SHIFT         => I_SHIFT         , -- Out :
            VALUE_START     => open            , -- Out :
            VALUE_ADDR      => param_addr      , -- Out :
            VALUE_VALID     => param_valid     , -- Out :
            VALUE_CODE      => param_code      , -- Out :
            VALUE_LAST      => param_last      , -- Out :
            VALUE_ERROR     => param_error     , -- In  :
            VALUE_DONE      => param_done      , -- In  :
            VALUE_SHIFT     => param_shift       -- In  :
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE: MsgPack_Object_Decode_Binary_Array   -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , --
            ADDR_BITS       => ADDR_BITS       , -- 
            SIZE_BITS       => SIZE_BITS       , --
            DATA_BITS       => DATA_BITS       , --
            DECODE_BINARY   => DECODE_BINARY   , --
            DECODE_STRING   => DECODE_STRING     --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            I_ADDR          => param_addr      , -- In  :
            I_CODE          => param_code      , -- In  :
            I_LAST          => param_last      , -- In  :
            I_VALID         => param_valid     , -- In  :
            I_ERROR         => param_error     , -- Out :
            I_DONE          => param_done      , -- Out :
            I_SHIFT         => param_shift     , -- Out :
            O_START         => START           , -- Out :
            O_BUSY          => BUSY            , -- Out :
            O_SIZE          => SIZE            , -- Out :
            O_ADDR          => ADDR            , -- Out :
            O_DATA          => DATA            , -- Out :
            O_STRB          => STRB            , -- Out :
            O_LAST          => LAST            , -- Out :
            O_VALID         => VALID           , -- Out :
            O_READY         => READY             -- In  :
        );                                       --
end RTL;
