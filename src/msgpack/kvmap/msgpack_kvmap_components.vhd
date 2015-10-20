-----------------------------------------------------------------------------------
--!     @file    kvmap/msgpack_kvmap_components.vhd                              --
--!     @brief   MessagaPack Component Library Description                       --
--!     @version 0.1.0                                                           --
--!     @date    2015/10/21                                                      --
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>                     --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--                                                                               --
--      Copyright (C) 2015 Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>           --
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
package MsgPack_KVMap_Components is
-----------------------------------------------------------------------------------
--! @brief MsgPack_KVMap_Key_Compare                                             --
-----------------------------------------------------------------------------------
component MsgPack_KVMap_Key_Compare
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      : positive := 1;
        I_MAX_PHASE     : positive := 1;
        KEYWORD         : string
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
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_REQ_PHASE     : in  std_logic_vector(I_MAX_PHASE-1 downto 0);
    -------------------------------------------------------------------------------
    -- Compare Result Output
    -------------------------------------------------------------------------------
        MATCH           : out std_logic;
        MISMATCH        : out std_logic;
        SHIFT           : out std_logic_vector(CODE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_KVMap_Key_Match_Aggregator                                    --
-----------------------------------------------------------------------------------
component MsgPack_KVMap_Key_Match_Aggregator
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      : positive := 1;
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
    -- Key Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_KEY_VALID     : in  std_logic;
        I_KEY_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_KEY_LAST      : in  std_logic := '0';
        I_KEY_SHIFT     : out std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_KEY_VALID     : out std_logic;
        O_KEY_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_KEY_LAST      : out std_logic;
        O_KEY_READY     : in  std_logic := '1';
    -------------------------------------------------------------------------------
    -- Key Object Compare Interface
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
--! @brief MsgPack_KVMap_Set_Integer                                             --
-----------------------------------------------------------------------------------
component MsgPack_KVMap_Set_Integer
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        KEY             :  STRING;
        CODE_WIDTH      :  positive := 1;
        MATCH_PHASE     :  positive := 8;
        VALUE_WIDTH     :  integer range 1 to 64;
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
    -- MessagePack Key Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        VALUE           : out std_logic_vector(VALUE_WIDTH-1 downto 0);
        SIGN            : out std_logic;
        WE              : out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_KVMap_Set_Value                                               --
-----------------------------------------------------------------------------------
component MsgPack_KVMap_Set_Value
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        STORE_SIZE      :  positive := 8;
        MATCH_PHASE     :  positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_KEY_CODE      : in  MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        I_KEY_LAST      : in  std_logic;
        I_KEY_VALID     : in  std_logic;
        I_KEY_ERROR     : out std_logic;
        I_KEY_DONE      : out std_logic;
        I_KEY_SHIFT     : out std_logic_vector(           CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_VAL_START     : in  std_logic;
        I_VAL_ABORT     : in  std_logic;
        I_VAL_CODE      : in  MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        I_VAL_LAST      : in  std_logic;
        I_VAL_VALID     : in  std_logic;
        I_VAL_ERROR     : out std_logic;
        I_VAL_DONE      : out std_logic;
        I_VAL_SHIFT     : out std_logic_vector(           CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_KEY_CODE      : out MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        O_KEY_VALID     : out std_logic;
        O_KEY_LAST      : out std_logic;
        O_KEY_ERROR     : out std_logic;
        O_KEY_READY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Compare Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector(          MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        MATCH_OK        : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        MATCH_NOT       : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        MATCH_SHIFT     : in  std_logic_vector(STORE_SIZE*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_VALID     : out std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_CODE      : out MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        VALUE_LAST      : out std_logic;
        VALUE_ERROR     : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_DONE      : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_SHIFT     : in  std_logic_vector(STORE_SIZE*CODE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_KVMap_Set_Map_Value                                           --
-----------------------------------------------------------------------------------
component MsgPack_KVMap_Set_Map_Value
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        STORE_SIZE      :  positive := 8;
        MATCH_PHASE     :  positive := 8
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
        I_CODE          : in  MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(           CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Object Compare Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector(          MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        MATCH_OK        : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        MATCH_NOT       : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        MATCH_SHIFT     : in  std_logic_vector(STORE_SIZE*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Decode Output Interface
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_VALID     : out std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_CODE      : out MsgPack_Object.Code_Vector( CODE_WIDTH-1 downto 0);
        VALUE_LAST      : out std_logic;
        VALUE_ERROR     : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_DONE      : in  std_logic_vector(STORE_SIZE           -1 downto 0);
        VALUE_SHIFT     : in  std_logic_vector(STORE_SIZE*CODE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_KVMap_Get_Integer                                             --
-----------------------------------------------------------------------------------
component MsgPack_KVMap_Get_Integer
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        KEY             : STRING;
        CODE_WIDTH      : positive := 1;
        MATCH_PHASE     : positive := 8;
        VALUE_WIDTH     : integer range 1 to 64;
        VALUE_SIGN      : boolean  := FALSE
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
    -- MessagePack Key Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        VALUE           : in  std_logic_vector(VALUE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_KVMap_Get_Value                                               --
-----------------------------------------------------------------------------------
component MsgPack_KVMap_Get_Value
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        STORE_SIZE      :  positive := 8;
        MATCH_PHASE     :  positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Decode Input Interface
    -------------------------------------------------------------------------------
        I_KEY_CODE      : in  MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        I_KEY_LAST      : in  std_logic;
        I_KEY_VALID     : in  std_logic;
        I_KEY_ERROR     : out std_logic;
        I_KEY_DONE      : out std_logic;
        I_KEY_SHIFT     : out std_logic_vector(                     CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_KEY_CODE      : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        O_KEY_VALID     : out std_logic;
        O_KEY_LAST      : out std_logic;
        O_KEY_ERROR     : out std_logic;
        O_KEY_READY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Value Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_VAL_CODE      : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        O_VAL_VALID     : out std_logic;
        O_VAL_LAST      : out std_logic;
        O_VAL_ERROR     : out std_logic;
        O_VAL_READY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Compare Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector(                    MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        MATCH_OK        : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        MATCH_NOT       : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        MATCH_SHIFT     : in  std_logic_vector(          STORE_SIZE*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_VALID     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_CODE      : in  MsgPack_Object.Code_Vector(STORE_SIZE*CODE_WIDTH-1 downto 0);
        VALUE_LAST      : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_ERROR     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_READY     : out std_logic_vector(          STORE_SIZE           -1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_KVMap_Get_Map_Value                                           --
-----------------------------------------------------------------------------------
component MsgPack_KVMap_Get_Map_Value
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        STORE_SIZE      :  positive := 8;
        MATCH_PHASE     :  positive := 8
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
        I_CODE          : in  MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(                     CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Key Value Map Encode Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        O_VALID         : out std_logic;
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Key Object Compare Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector(                    MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_Object.Code_Vector(           CODE_WIDTH-1 downto 0);
        MATCH_OK        : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        MATCH_NOT       : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        MATCH_SHIFT     : in  std_logic_vector(          STORE_SIZE*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_VALID     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_CODE      : in  MsgPack_Object.Code_Vector(STORE_SIZE*CODE_WIDTH-1 downto 0);
        VALUE_LAST      : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_ERROR     : in  std_logic_vector(          STORE_SIZE           -1 downto 0);
        VALUE_READY     : out std_logic_vector(          STORE_SIZE           -1 downto 0)
    );
end component;
end MsgPack_KVMap_Components;
