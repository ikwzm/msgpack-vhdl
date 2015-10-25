-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_integer_stream.vhd
--!     @brief   MessagePack Object decode to integer stream
--!     @version 0.1.0
--!     @date    2015/10/22
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
entity  MsgPack_Object_Decode_Integer_Stream is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
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
        O_SIGN          : out std_logic;
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end  MsgPack_Object_Decode_Integer_Stream;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Array;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Integer;
architecture RTL of MsgPack_Object_Decode_Integer_Stream is
    signal    value_valid       :  std_logic;
    signal    value_error       :  std_logic;
    signal    value_done        :  std_logic;
    signal    value_last        :  std_logic;
    signal    value_code        :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    value_shift       :  std_logic_vector(CODE_WIDTH-1 downto 0);
    signal    outlet_valid      :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE_ARRAY:  MsgPack_Object_Decode_Array       -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH            --
        )                                            -- 
        port map (                                   -- 
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
            I_CODE          => I_CODE              , -- In  :
            I_LAST          => I_LAST              , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_ERROR         => I_ERROR             , -- Out :
            I_DONE          => I_DONE              , -- Out :
            I_SHIFT         => I_SHIFT             , -- Out :
            ARRAY_START     => O_START             , -- Out :
            ARRAY_SIZE      => open                , -- Out :
            VALUE_START     => open                , -- Out :
            VALUE_VALID     => value_valid         , -- Out :
            VALUE_CODE      => value_code          , -- Out :
            VALUE_LAST      => value_last          , -- Out :
            VALUE_ERROR     => value_error         , -- In  :
            VALUE_DONE      => value_done          , -- In  :
            VALUE_SHIFT     => value_shift           -- In  :
        );                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE_VALUE: MsgPack_Object_Decode_Integer      -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH          , --
            VALUE_BITS      => VALUE_BITS          , --
            VALUE_SIGN      => VALUE_SIGN          , --
            QUEUE_SIZE      => QUEUE_SIZE          , --
            CHECK_RANGE     => CHECK_RANGE         , --
            ENABLE64        => ENABLE64              --
        )                                            -- 
        port map (                                   -- 
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
            I_CODE          => value_code          , -- In  :
            I_LAST          => value_last          , -- In  :
            I_VALID         => value_valid         , -- In  :
            I_ERROR         => value_error         , -- Out :
            I_DONE          => value_done          , -- Out :
            I_SHIFT         => value_shift         , -- Out :
            O_VALUE         => O_VALUE             , -- Out :
            O_SIGN          => O_SIGN              , -- Out :
            O_LAST          => O_LAST              , -- Out :
            O_VALID         => O_VALID             , -- Out :
            O_READY         => O_READY               -- In  :
        );                                           --
end RTL;
