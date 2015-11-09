-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_integer_stream.vhd
--!     @brief   MessagePack Object encode to integer stream
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
entity  MsgPack_Object_Encode_Integer_Stream is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
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
        SIZE            : in  std_logic_vector( SIZE_BITS-1 downto 0);
        BUSY            : out std_logic;
    -------------------------------------------------------------------------------
    -- Integer Value Input Interface
    -------------------------------------------------------------------------------
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
end MsgPack_Object_Encode_Integer_Stream;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Reducer;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_Array;
architecture RTL of MsgPack_Object_Encode_Integer_Stream is
    constant  CODE_DATA_BITS    :  integer := MsgPack_Object.CODE_DATA_BITS;
    constant  I_WIDTH           :  integer := (VALUE_BITS+CODE_DATA_BITS-1)/CODE_DATA_BITS;
    signal    i_code            :  MsgPack_Object.Code_Vector(I_WIDTH-1 downto 0);
    signal    t_code            :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    signal    t_last            :  std_logic;
    constant  t_error           :  std_logic := '0';
    signal    t_valid           :  std_logic;
    signal    t_ready           :  std_logic;
    signal    t_shift           :  std_logic_vector(CODE_WIDTH-1 downto 0);
    signal    queue_busy        :  std_logic;
    signal    i_enable          :  std_logic;
    signal    i_last            :  std_logic;
    signal    q_ready           :  std_logic;
    type      STATE_TYPE        is (IDLE_STATE, START_STATE, RUN_STATE);
    signal    curr_state        :  STATE_TYPE;
    signal    curr_count        :  unsigned(SIZE_BITS-1 downto 0);
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
    QUEUE: MsgPack_Object_Code_Reducer            -- 
        generic map (                             -- 
            I_WIDTH         => I_WIDTH          , -- 
            O_WIDTH         => CODE_WIDTH       , --
            O_VALID_SIZE    => CODE_WIDTH       , -- 
            QUEUE_SIZE      => QUEUE_SIZE         --
        )                                         -- 
        port map (                                -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals
        ---------------------------------------------------------------------------
            CLK             => CLK              , -- In  :
            RST             => RST              , -- In  :
            CLR             => CLR              , -- In  :
        ---------------------------------------------------------------------------
        -- Control and Status Signals
        ---------------------------------------------------------------------------
            DONE            => '0'              , -- In  :
            BUSY            => queue_busy       , -- Out :
        ---------------------------------------------------------------------------
        -- Object Code Input Interface
        ---------------------------------------------------------------------------
            I_ENABLE        => i_enable         , -- In  :
            I_CODE          => i_code           , -- In  :
            I_DONE          => i_last           , -- In  :
            I_VALID         => I_VALID          , -- In  :
            I_READY         => q_ready          , -- Out :
        ---------------------------------------------------------------------------
        -- Object Code Output Interface
        ---------------------------------------------------------------------------
            O_ENABLE        => '1'              , -- In  :
            O_CODE          => t_code           , -- Out :
            O_DONE          => open             , -- Out :
            O_VALID         => t_valid          , -- Out :
            O_READY         => t_ready          , -- In  :
            O_SHIFT         => t_shift            -- In  :
    );                                            -- 
    I_READY  <= q_ready;                          -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (t_code)
        variable shift :  std_logic_vector(CODE_WIDTH-1 downto 0);
        variable last  :  std_logic;
    begin
        last := '0';
        for i in 0 to CODE_WIDTH-1 loop
            if (last = '0' and t_code(i).valid = '1') then
                shift(i) := '1';
            else
                shift(i) := '0';
            end if;
            if (t_code(i).valid = '1' and t_code(i).complete = '1') then
                last := '1';
            end if;
        end loop;
        t_last  <= last;
        t_shift <= shift;
    end process;        
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ENCODE_ARRAY: MsgPack_Object_Encode_Array     -- 
        generic map (                             -- 
             CODE_WIDTH      => CODE_WIDTH      , --
             SIZE_BITS       => SIZE_BITS         -- 
        )                                         -- 
        port map (                                -- 
             CLK             => CLK             , -- In  :
             RST             => RST             , -- In  :
             CLR             => CLR             , -- In  :
             START           => START           , -- In  :
             SIZE            => SIZE            , -- In  :
             I_CODE          => t_code          , -- In  :
             I_LAST          => t_last          , -- In  :
             I_ERROR         => t_error         , -- In  :
             I_VALID         => t_valid         , -- In  :
             I_READY         => t_ready         , -- Out :
             O_CODE          => O_CODE          , -- Out :
             O_LAST          => O_LAST          , -- Out :
             O_ERROR         => O_ERROR         , -- Out :
             O_VALID         => O_VALID         , -- Out :
             O_READY         => O_READY           -- In  :
    );                                            -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    i_enable <= '1' when (curr_state = START_STATE and to_01(curr_count) > 0) or
                         (curr_state = RUN_STATE  ) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
                curr_count <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
                curr_count <= (others => '0');
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (START = '1') then
                            curr_state <= START_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                        curr_count <= unsigned(SIZE);
                    when START_STATE =>
                        if (curr_count > 0) then
                            curr_state <= RUN_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                    when RUN_STATE   =>
                        if (I_VALID = '1' and i_last = '1' and q_ready = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= RUN_STATE;
                        end if;
                        if (I_VALID = '1' and q_ready = '1') then
                            curr_count <= curr_count - 1;
                        end if;
                    when others => 
                        curr_state <= IDLE_STATE;
                        curr_count <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    i_last <= '1' when (to_01(curr_count) <= 1) else '0';
    BUSY   <= '1' when (curr_state = RUN_STATE or queue_busy = '1') else '0';
end RTL;
