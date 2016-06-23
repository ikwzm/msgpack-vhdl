-----------------------------------------------------------------------------------
--!     @file    msgpack_object_query_binary_stream.vhd
--!     @brief   MessagePack Object Query to Binary/String Stream
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
entity  MsgPack_Object_Query_Binary_Stream is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 32;
        SIZE_BITS       :  integer range 1 to 32 := 32;
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
    -- Default(when parameter == nil) Query Size 
    -------------------------------------------------------------------------------
        DEFAULT_SIZE    : in  std_logic_vector(SIZE_BITS  -1 downto 0) := (others => '1');
    -------------------------------------------------------------------------------
    -- MessagePack Object Code Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH -1 downto 0);
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
        START           : out std_logic;
        BUSY            : out std_logic;
        SIZE            : out std_logic_vector(SIZE_BITS  -1 downto 0);
        DATA            : in  std_logic_vector(DATA_BITS  -1 downto 0);
        STRB            : in  std_logic_vector(DATA_BITS/8-1 downto 0);
        LAST            : in  std_logic;
        VALID           : in  std_logic;
        READY           : out std_logic
    );
end MsgPack_Object_Query_Binary_Stream;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_Binary_Stream;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Query_Stream_Parameter;
architecture RTL of MsgPack_Object_Query_Binary_Stream is
    signal    param_start    :  std_logic;
    signal    param_busy     :  std_logic;
    signal    param_size     :  std_logic_vector(SIZE_BITS-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PARAM: MsgPack_Object_Query_Stream_Parameter --
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , --
            SIZE_BITS       => SIZE_BITS         --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            DEFAULT_SIZE    => DEFAULT_SIZE    , -- In  :
            I_CODE          => I_CODE          , -- In  :
            I_LAST          => I_LAST          , -- In  :
            I_VALID         => I_VALID         , -- In  :
            I_ERROR         => I_ERROR         , -- Out :
            I_DONE          => I_DONE          , -- Out :
            I_SHIFT         => I_SHIFT         , -- Out :
            START           => param_start     , -- Out :
            SIZE            => param_size      , -- Out :
            BUSY            => param_busy        -- In  :
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ENCODE: MsgPack_Object_Encode_Binary_Stream  -- 
        generic map (                            -- 
            CODE_WIDTH      => CODE_WIDTH      , --
            DATA_BITS       => DATA_BITS       , --
            SIZE_BITS       => SIZE_BITS       , --
            ENCODE_BINARY   => ENCODE_BINARY   , --
            ENCODE_STRING   => ENCODE_STRING   , --
            I_JUSTIFIED     => FALSE           , --
            I_BUFFERED      => TRUE              --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            START           => param_start     , -- In  :
            SIZE            => param_size      , -- In  :
            BUSY            => param_busy      , -- Out :
            READY           => open            , -- Out :
            I_START         => START           , -- Out :
            I_BUSY          => BUSY            , -- Out :
            I_SIZE          => SIZE            , -- Out :
            I_DATA          => DATA            , -- In  :
            I_STRB          => STRB            , -- In  :
            I_LAST          => LAST            , -- In  :
            I_VALID         => VALID           , -- In  :
            I_READY         => READY           , -- Out :
            O_CODE          => O_CODE          , -- Out :
            O_LAST          => O_LAST          , -- Out :
            O_ERROR         => O_ERROR         , -- Out :
            O_VALID         => O_VALID         , -- Out :
            O_READY         => O_READY           -- In  :
        );                                       --
end RTL;
