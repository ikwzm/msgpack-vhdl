-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_integer.vhd
--!     @brief   MessagePack Object encode integer :
--!     @version 0.2.0
--!     @date    2016/6/23
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2012-2016 Ichiro Kawazome
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
entity  MsgPack_Object_Encode_Integer is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
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
    -- Control and Status Signals 
    -------------------------------------------------------------------------------
        START           : in  std_logic := '1';
        BUSY            : out std_logic;
        READY           : out std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Integer Value Input
    -------------------------------------------------------------------------------
        I_VALUE         : in  std_logic_vector(VALUE_BITS-1 downto 0);
        I_VALID         : in  std_logic;
        I_READY         : out std_logic
    );
end MsgPack_Object_Encode_Integer;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Reducer;
architecture RTL of MsgPack_Object_Encode_Integer is
    function  max(A,B:integer) return integer is begin
        if (A>B) then return A;
        else          return B;
        end if;
    end function;
    constant  CODE_DATA_BITS    :  integer := MsgPack_Object.CODE_DATA_BITS;
    constant  I_WIDTH           :  integer := (VALUE_BITS+CODE_DATA_BITS-1)/CODE_DATA_BITS;
    signal    i_code            :  MsgPack_Object.Code_Vector(I_WIDTH-1 downto 0);
    constant  o_shift           :  std_logic_vector(CODE_WIDTH-1 downto 0) := (others => '1');
    constant  I_QUEUE_SIZE      :  integer := max(QUEUE_SIZE, max(CODE_WIDTH, I_WIDTH));
    signal    queue_busy        :  std_logic;
    signal    i_enable          :  std_logic;
    signal    q_ready           :  std_logic;
    type      STATE_TYPE        is (RESET_STATE, IDLE_STATE, RUN_STATE);
    signal    curr_state        :  STATE_TYPE;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    S_INT: if (VALUE_SIGN = TRUE ) generate
        i_code <= MsgPack_Object.New_Code_Vector_Integer(I_WIDTH,   signed(I_VALUE));
    end generate;
    U_INT: if (VALUE_SIGN = FALSE) generate
        i_code <= MsgPack_Object.New_Code_Vector_Integer(I_WIDTH, unsigned(I_VALUE));
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    QUEUE: MsgPack_Object_Code_Reducer              -- 
        generic map (                               -- 
            I_WIDTH         => I_WIDTH            , -- 
            O_WIDTH         => CODE_WIDTH         , --
            O_VALID_SIZE    => CODE_WIDTH         , -- 
            QUEUE_SIZE      => I_QUEUE_SIZE         --
        )                                           -- 
        port map (                                  -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK                , -- In  :
            RST             => RST                , -- In  :
            CLR             => CLR                , -- In  :
        ---------------------------------------------------------------------------
        -- Control and Status Signals
        ---------------------------------------------------------------------------
            DONE            => '0'                , -- In  :
            BUSY            => queue_busy         , -- Out :
        ---------------------------------------------------------------------------
        -- Object Code Input Interface
        ---------------------------------------------------------------------------
            I_ENABLE        => i_enable           , -- In  :
            I_CODE          => i_code             , -- In  :
            I_DONE          => '1'                , -- In  :
            I_VALID         => I_VALID            , -- In  :
            I_READY         => q_ready            , -- Out :
        ---------------------------------------------------------------------------
        -- Object Code Output Interface
        ---------------------------------------------------------------------------
            O_ENABLE        => '1'                , -- In  :
            O_CODE          => O_CODE             , -- Out :
            O_DONE          => O_LAST             , -- Out :
            O_VALID         => O_VALID            , -- Out :
            O_READY         => O_READY            , -- In  :
            O_SHIFT         => o_shift              -- In  :
    );                                              -- 
    O_ERROR  <= '0';
    I_READY  <= q_ready;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    i_enable <= '1' when (curr_state = IDLE_STATE and START = '1') or
                         (curr_state = RUN_STATE                 ) else '0';
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state <= RESET_STATE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= RESET_STATE;
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (START = '1') then
                            curr_state <= RUN_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                    when RUN_STATE  =>
                        if (I_VALID = '1' and q_ready = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= RUN_STATE;
                        end if;
                    when others => 
                            curr_state <= IDLE_STATE;
                end case;
            end if;
        end if;
    end process;
    BUSY  <= '1' when (curr_state = RUN_STATE  or  queue_busy = '1') else '0';
    READY <= '1' when (curr_state = IDLE_STATE and queue_busy = '0') else '0';
end RTL;
