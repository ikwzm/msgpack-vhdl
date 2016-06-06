-----------------------------------------------------------------------------------
--!     @file    object/msgpack_object_components.vhd                            --
--!     @brief   MessagaPack Component Library Description                       --
--!     @version 0.2.0                                                           --
--!     @date    2016/06/07                                                      --
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>                     --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--                                                                               --
--      Copyright (C) 2016 Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>           --
--      All rights reserved.                                                     --
--                                                                               --
--      Redistribution and use in source and binary forms, with or without       --
--      modification, are permitted provided that the following conditions       --
--      are met:                                                                 --
--                                                                               --
--        1. Redistributions of source code must retain the above copyright      --
--           notice, this list of conditions and the following disclaimer.       --
--                                                                               --
--        2. Redistributions in binary form must reproduce the above copyright   --
--           notice, this list of conditions and the following disclaimer in     --
--           the documentation and/or other materials provided with the          --
--           distribution.                                                       --
--                                                                               --
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS      --
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT        --
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR    --
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT    --
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    --
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT         --
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,    --
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY    --
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT      --
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE    --
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.     --
--                                                                               --
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
-----------------------------------------------------------------------------------
--! @brief MessagaPack Component Library Description                             --
-----------------------------------------------------------------------------------
package MsgPack_Object_Components is
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Packer                                                 --
-----------------------------------------------------------------------------------
component MsgPack_Object_Packer
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      : positive := 1;
        O_BYTES         : positive := 1
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
        I_SHIFT         : out std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Byte Stream Output Interface
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(           8*O_BYTES-1 downto 0);
        O_STRB          : out std_logic_vector(             O_BYTES-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Unpacker                                               --
-----------------------------------------------------------------------------------
component MsgPack_Object_Unpacker
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        I_BYTES         : positive := 1;
        CODE_WIDTH      : positive := 1;
        O_VALID_SIZE    : integer range 0 to 64 := 1;
        DECODE_UNIT     : integer range 0 to  3 := 1;
        SHORT_STR_SIZE  : integer range 0 to 31 := 8;
        STACK_DEPTH     : integer := 4
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Byte Stream Input Interface
    -------------------------------------------------------------------------------
        I_DATA          : in  std_logic_vector(           8*I_BYTES-1 downto 0);
        I_STRB          : in  std_logic_vector(             I_BYTES-1 downto 0);
        I_LAST          : in  std_logic := '0';
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
        O_SHIFT         : in  std_logic_vector(          CODE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Code_Reducer                                           --
-----------------------------------------------------------------------------------
component MsgPack_Object_Code_Reducer
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
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Code_FIFO                                              --
-----------------------------------------------------------------------------------
component MsgPack_Object_Code_FIFO
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        WIDTH           :  positive := 1;
        DEPTH           :  positive := 1
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
        I_CODE          : in  MsgPack_Object.Code_Vector(WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Code_Compare                                           --
-----------------------------------------------------------------------------------
component MsgPack_Object_Code_Compare
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        C_WIDTH         : positive := 1;
        I_WIDTH         : positive := 1;
        I_MAX_PHASE     : positive := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Input Object Code Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(I_WIDTH-1 downto 0);
        I_REQ_PHASE     : in  std_logic_vector(I_MAX_PHASE-1 downto 0);
    -------------------------------------------------------------------------------
    -- Comparison Object Code Interface
    -------------------------------------------------------------------------------
        C_CODE          : in  MsgPack_Object.Code_Vector(C_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Compare Result Output 
    -------------------------------------------------------------------------------
        MATCH           : out std_logic;
        MISMATCH        : out std_logic;
        SHIFT           : out std_logic_vector(I_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Decode_Array                                           --
-----------------------------------------------------------------------------------
component MsgPack_Object_Decode_Array
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1
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
    -- 
    -------------------------------------------------------------------------------
        ARRAY_START     : out std_logic;
        ARRAY_SIZE      : out std_logic_vector(31 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        ENTRY_START     : out std_logic;
        ENTRY_BUSY      : out std_logic;
        ENTRY_LAST      : out std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic;
        VALUE_VALID     : out std_logic;
        VALUE_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        VALUE_LAST      : out std_logic;
        VALUE_ERROR     : in  std_logic;
        VALUE_DONE      : in  std_logic;
        VALUE_SHIFT     : in  std_logic_vector(CODE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Decode_Binary_Core                                     --
-----------------------------------------------------------------------------------
component MsgPack_Object_Decode_Binary_Core
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
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
        I_SHIFT         : out std_logic_vector(CODE_WIDTH -1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Output Interface
    -------------------------------------------------------------------------------
        O_ENABLE        : out std_logic;
        O_START         : out std_logic;
        O_SIZE          : out std_logic_vector(MsgPack_Object.CODE_DATA_BITS           -1 downto 0);
        O_DATA          : out std_logic_vector(MsgPack_Object.CODE_DATA_BITS*CODE_WIDTH-1 downto 0);
        O_STRB          : out std_logic_vector(MsgPack_Object.CODE_STRB_BITS*CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Decode_Binary_Array                                    --
-----------------------------------------------------------------------------------
component MsgPack_Object_Decode_Binary_Array
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 4;
        ADDR_BITS       :  integer  := 8;
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
        I_ADDR          : in  std_logic_vector(ADDR_BITS  -1 downto 0);
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH -1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Output Interface
    -------------------------------------------------------------------------------
        O_ADDR          : out std_logic_vector(ADDR_BITS  -1 downto 0);
        O_DATA          : out std_logic_vector(DATA_BITS  -1 downto 0);
        O_STRB          : out std_logic_vector(DATA_BITS/8-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Decode_Binary_Stream                                   --
-----------------------------------------------------------------------------------
component MsgPack_Object_Decode_Binary_Stream
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 4;
        ADDR_BITS       :  integer  := 8;
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
        I_SHIFT         : out std_logic_vector(CODE_WIDTH -1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Output Interface
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(DATA_BITS  -1 downto 0);
        O_STRB          : out std_logic_vector(DATA_BITS/8-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Decode_Map                                             --
-----------------------------------------------------------------------------------
component MsgPack_Object_Decode_Map
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1
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
    -- 
    -------------------------------------------------------------------------------
        MAP_START       : out std_logic;
        MAP_SIZE        : out std_logic_vector(31 downto 0);
        MAP_LAST        : out std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        KEY_START       : out std_logic;
        KEY_VALID       : out std_logic;
        KEY_CODE        : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        KEY_LAST        : out std_logic;
        KEY_ERROR       : in  std_logic;
        KEY_DONE        : in  std_logic;
        KEY_SHIFT       : in  std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic;
        VALUE_ABORT     : out std_logic;
        VALUE_VALID     : out std_logic;
        VALUE_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        VALUE_LAST      : out std_logic;
        VALUE_ERROR     : in  std_logic;
        VALUE_DONE      : in  std_logic;
        VALUE_SHIFT     : in  std_logic_vector(CODE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Decode_Integer                                         --
-----------------------------------------------------------------------------------
component MsgPack_Object_Decode_Integer
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
    -- Integer Value Output Interface
    -------------------------------------------------------------------------------
        O_VALUE         : out std_logic_vector(VALUE_BITS-1 downto 0);
        O_SIGN          : out std_logic;
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Decode_Integer_Stream                                  --
-----------------------------------------------------------------------------------
component MsgPack_Object_Decode_Integer_Stream
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
        O_BUSY          : out std_logic;
        O_VALUE         : out std_logic_vector(VALUE_BITS-1 downto 0);
        O_SIGN          : out std_logic;
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Decode_Integer_Array                                   --
-----------------------------------------------------------------------------------
component MsgPack_Object_Decode_Integer_Array
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
        O_BUSY          : out std_logic;
        O_VALUE         : out std_logic_vector(VALUE_BITS-1 downto 0);
        O_ADDR          : out std_logic_vector( ADDR_BITS-1 downto 0);
        O_SIGN          : out std_logic;
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Encode_Array                                           --
-----------------------------------------------------------------------------------
component MsgPack_Object_Encode_Array
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        SIZE_BITS       :  positive := 32
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
        SIZE            : in  std_logic_vector(SIZE_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_ERROR         : in  std_logic;
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
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Encode_Map                                             --
-----------------------------------------------------------------------------------
component MsgPack_Object_Encode_Map
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        SIZE_BITS       :  positive := 32
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
        SIZE            : in  std_logic_vector(SIZE_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Object Encode Input Interface
    -------------------------------------------------------------------------------
        I_KEY_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_KEY_LAST      : in  std_logic;
        I_KEY_ERROR     : in  std_logic;
        I_KEY_VALID     : in  std_logic;
        I_KEY_READY     : out std_logic;
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        I_VAL_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_VAL_LAST      : in  std_logic;
        I_VAL_ERROR     : in  std_logic;
        I_VAL_VALID     : in  std_logic;
        I_VAL_READY     : out std_logic;
    -------------------------------------------------------------------------------
    -- Key Value Map Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_MAP_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_MAP_LAST      : out std_logic;
        O_MAP_ERROR     : out std_logic;
        O_MAP_VALID     : out std_logic;
        O_MAP_READY     : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Encode_Binary_Array                                    --
-----------------------------------------------------------------------------------
component MsgPack_Object_Encode_Binary_Array
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
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Encode_Binary_Stream                                   --
-----------------------------------------------------------------------------------
component MsgPack_Object_Encode_Binary_Stream
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DATA_BITS       :  positive := 32;
        SIZE_BITS       :  positive := 32;
        ENCODE_BINARY   :  boolean  := TRUE;
        ENCODE_STRING   :  boolean  := FALSE;
        I_JUSTIFIED     :  boolean  := TRUE;
        I_BUFFERED      :  boolean  := FALSE
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
        I_DATA          : in  std_logic_vector(DATA_BITS  -1 downto 0);
        I_STRB          : in  std_logic_vector(DATA_BITS/8-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Encode_Integer                                         --
-----------------------------------------------------------------------------------
component MsgPack_Object_Encode_Integer
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
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Encode_Integer_Stream                                  --
-----------------------------------------------------------------------------------
component MsgPack_Object_Encode_Integer_Stream
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
        I_START         : out std_logic;
        I_BUSY          : out std_logic;
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
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Encode_Integer_Array                                   --
-----------------------------------------------------------------------------------
component MsgPack_Object_Encode_Integer_Array
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
        I_START         : out std_logic;
        I_BUSY          : out std_logic;
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
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Encode_String_Constant                                 --
-----------------------------------------------------------------------------------
component MsgPack_Object_Encode_String_Constant
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        VALUE           : string;
        CODE_WIDTH      : positive := 1
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
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Structure_Stack                                               --
-----------------------------------------------------------------------------------
component MsgPack_Structure_Stack
    generic (
        DEPTH           : integer :=  4
    );
    port (
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
        I_SIZE          : in  std_logic_vector(31 downto 0);
        I_MAP           : in  std_logic;
        I_ARRAY         : in  std_logic;
        I_COMPLETE      : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
        O_LAST          : out std_logic;
        O_NONE          : out std_logic;
        O_FULL          : out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Match_Aggregator                                       --
-----------------------------------------------------------------------------------
component MsgPack_Object_Match_Aggregator
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH         : positive := 1;
        MATCH_NUM       : integer  := 1;
        MATCH_PHASE     : integer  := 8
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
        I_VALID         : in  std_logic;
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic := '0';
        I_SHIFT         : out std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Phase Control Status Signals
    -------------------------------------------------------------------------------
        PHASE_NEXT      : out std_logic;
        PHASE_READY     : in  std_logic := '1';
    -------------------------------------------------------------------------------
    -- Object Code Compare Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector(         MATCH_PHASE-1 downto 0);
        MATCH_OK        : in  std_logic_vector(MATCH_NUM           -1 downto 0);
        MATCH_NOT       : in  std_logic_vector(MATCH_NUM           -1 downto 0);
        MATCH_SHIFT     : in  std_logic_vector(MATCH_NUM*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Aggregated Result Output
    -------------------------------------------------------------------------------
        MATCH_SEL       : out std_logic_vector(MATCH_NUM           -1 downto 0);
        MATCH_STATE     : out MsgPack_Object.Match_State_Type
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Store_Array                                            --
-----------------------------------------------------------------------------------
component MsgPack_Object_Store_Array
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        ADDR_BITS       :  integer  := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Value Map Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Decode Output Interface
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic;
        VALUE_ADDR      : out std_logic_vector(           ADDR_BITS-1 downto 0);
        VALUE_VALID     : out std_logic;
        VALUE_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        VALUE_LAST      : out std_logic;
        VALUE_ERROR     : in  std_logic;
        VALUE_DONE      : in  std_logic;
        VALUE_SHIFT     : in  std_logic_vector(          CODE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Store_Integer_Register                                 --
-----------------------------------------------------------------------------------
component MsgPack_Object_Store_Integer_Register
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE;
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
    -- Value Output Interface
    -------------------------------------------------------------------------------
        VALUE           : out std_logic_vector(VALUE_BITS-1 downto 0);
        SIGN            : out std_logic;
        LAST            : out std_logic;
        VALID           : out std_logic;
        READY           : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Store_Integer_Array                                    --
-----------------------------------------------------------------------------------
component MsgPack_Object_Store_Integer_Array
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        ADDR_BITS       :  integer  := 8;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE;
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
        START           : out std_logic;
        BUSY            : out std_logic;
        ADDR            : out std_logic_vector( ADDR_BITS-1 downto 0);
        VALUE           : out std_logic_vector(VALUE_BITS-1 downto 0);
        SIGN            : out std_logic;
        LAST            : out std_logic;
        VALID           : out std_logic;
        READY           : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Store_Integer_Stream                                   --
-----------------------------------------------------------------------------------
component MsgPack_Object_Store_Integer_Stream
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE;
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
        START           : out std_logic;
        BUSY            : out std_logic;
        VALUE           : out std_logic_vector(VALUE_BITS-1 downto 0);
        SIGN            : out std_logic;
        LAST            : out std_logic;
        VALID           : out std_logic;
        READY           : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Query_Stream_Parameter                                 --
-----------------------------------------------------------------------------------
component MsgPack_Object_Query_Stream_Parameter
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
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Query_Integer_Register                                 --
-----------------------------------------------------------------------------------
component MsgPack_Object_Query_Integer_Register
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE
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
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        VALUE           : in  std_logic_vector(VALUE_BITS-1 downto 0);
        VALID           : in  std_logic;
        READY           : out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Query_Integer_Array                                    --
-----------------------------------------------------------------------------------
component MsgPack_Object_Query_Integer_Array
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        ADDR_BITS       :  positive := 32;
        SIZE_BITS       :  positive := 32;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE
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
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Integer Value Input Interface
    -------------------------------------------------------------------------------
        START           : out std_logic;
        BUSY            : out std_logic;
        ADDR            : out std_logic_vector( ADDR_BITS-1 downto 0);
        VALUE           : in  std_logic_vector(VALUE_BITS-1 downto 0);
        VALID           : in  std_logic;
        READY           : out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Query_Integer_Stream                                   --
-----------------------------------------------------------------------------------
component MsgPack_Object_Query_Integer_Stream
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        SIZE_BITS       :  positive := 32;
        SIZE_MAX        :  positive := 32;
        VALUE_BITS      :  integer range 1 to 64;
        VALUE_SIGN      :  boolean  := FALSE
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
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Integer Value Input Interface
    -------------------------------------------------------------------------------
        START           : out std_logic;
        BUSY            : out std_logic;
        VALUE           : in  std_logic_vector(VALUE_BITS-1 downto 0);
        VALID           : in  std_logic;
        READY           : out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_Object_Query_Array                                            --
-----------------------------------------------------------------------------------
component MsgPack_Object_Query_Array
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        ADDR_BITS       :  integer  := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Array Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Value Map Encode Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_VALID         : out std_logic;
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Parameter Object Decode Output Interface
    -------------------------------------------------------------------------------
        PARAM_START     : out std_logic;
        PARAM_ADDR      : out std_logic_vector(           ADDR_BITS-1 downto 0);
        PARAM_VALID     : out std_logic;
        PARAM_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        PARAM_LAST      : out std_logic;
        PARAM_ERROR     : in  std_logic;
        PARAM_DONE      : in  std_logic;
        PARAM_SHIFT     : in  std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        VALUE_VALID     : in  std_logic;
        VALUE_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        VALUE_LAST      : in  std_logic;
        VALUE_ERROR     : in  std_logic;
        VALUE_READY     : out std_logic
    );
end component;
end MsgPack_Object_Components;
