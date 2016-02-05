-----------------------------------------------------------------------------------
--!     @file    msgpack_kvmap_decode_get_stream_parameter.vhd
--!     @brief   MessagePack-KVMap(Key Value Map) decode get stream parameter Module :
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
entity  MsgPack_KVMap_Decode_Get_Stream_Parameter is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        SIZE_BITS       :  positive := 32;  
        SIZE_MAX        :  positive := 1
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
    -- 
    -------------------------------------------------------------------------------
        START           : out std_logic;
        SIZE            : out std_logic_vector(SIZE_BITS -1 downto 0);
        BUSY            : in  std_logic
    );
end MsgPack_KVMap_Decode_Get_Stream_Parameter;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Integer;
architecture RTL of MsgPack_KVMap_Decode_Get_Stream_Parameter is
    signal    integer_i_error   :  std_logic;
    signal    integer_i_done    :  std_logic;
    signal    integer_i_shift   :  std_logic_vector(CODE_WIDTH-1 downto 0);
    signal    integer_valid     :  std_logic;
    signal    integer_value     :  std_logic_vector( SIZE_BITS-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DECODE_INTEGER: MsgPack_Object_Decode_Integer    -- 
        generic map (                                -- 
            CODE_WIDTH      => CODE_WIDTH          , --
            VALUE_BITS      => SIZE_BITS           , --
            VALUE_SIGN      => FALSE               , --
            QUEUE_SIZE      => 0                   , -- Must 0 !
            CHECK_RANGE     => FALSE               , --
            ENABLE64        => FALSE                 --
        )                                            -- 
        port map (                                   -- 
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
            I_CODE          => I_CODE              , -- In  :
            I_LAST          => I_LAST              , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_ERROR         => integer_i_error     , -- Out :
            I_DONE          => integer_i_done      , -- Out :
            I_SHIFT         => integer_i_shift     , -- Out :
            O_VALUE         => integer_value       , -- Out :
            O_SIGN          => open                , -- Out :
            O_LAST          => open                , -- Out :
            O_VALID         => integer_valid       , -- Out :
            O_READY         => '1'                   -- In  :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (I_VALID, I_CODE, BUSY, integer_i_error, integer_i_done, integer_i_shift, integer_value, integer_valid) begin
        if (I_VALID = '1' and I_CODE(0).valid = '1' and BUSY = '0') then
            if    (I_CODE(0).class = MsgPack_Object.CLASS_NIL) then
                SIZE      <= std_logic_vector(to_unsigned(SIZE_MAX, SIZE_BITS));
                START     <= '1';
                I_ERROR   <= '0';
                I_DONE    <= '1';
                I_SHIFT   <= (0 => '1', others => '0');
            elsif (integer_i_done = '1' and integer_i_error = '0') then
                SIZE      <= integer_value;
                START     <= integer_valid;
                I_ERROR   <= '0';
                I_DONE    <= '1';
                I_SHIFT   <= integer_i_shift;
            else
                SIZE      <= std_logic_vector(to_unsigned(SIZE_MAX, SIZE_BITS));
                START     <= '0';
                I_ERROR   <= '1';
                I_DONE    <= '1';
                I_SHIFT   <= (others => '0');
            end if;
        else
                SIZE      <= std_logic_vector(to_unsigned(SIZE_MAX, SIZE_BITS));
                START     <= '0';
                I_ERROR   <= '0';
                I_DONE    <= '0';
                I_SHIFT   <= (others => '0');
        end if;
    end process;
end RTL;
