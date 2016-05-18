-----------------------------------------------------------------------------------
--!     @file    rpc/msgpack_rpc_components.vhd                                  --
--!     @brief   MessagaPack Component Library Description                       --
--!     @version 0.2.0                                                           --
--!     @date    2016/05/18                                                      --
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
use     MsgPack.MsgPack_RPC;
-----------------------------------------------------------------------------------
--! @brief MessagaPack Component Library Description                             --
-----------------------------------------------------------------------------------
package MsgPack_RPC_Components is
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Server                                                    --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Server
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        I_BYTES         : positive := 1;
        O_BYTES         : positive := 1;
        PROC_NUM        : positive := 1;
        MATCH_PHASE     : positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Byte Data Stream Input Interface
    -------------------------------------------------------------------------------
        I_DATA          : in  std_logic_vector(8*I_BYTES-1 downto 0);
        I_STRB          : in  std_logic_vector(  I_BYTES-1 downto 0);
        I_LAST          : in  std_logic := '0';
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Byte Data Stream Output Interface
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(8*O_BYTES-1 downto 0);
        O_STRB          : out std_logic_vector(  O_BYTES-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector     (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_RPC.Code_Type;
        MATCH_OK        : in  std_logic_vector        (PROC_NUM-1 downto 0);
        MATCH_NOT       : in  std_logic_vector        (PROC_NUM-1 downto 0);
        MATCH_SHIFT     : in  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Request Interface
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : out MsgPack_RPC.MsgID_Type;
        PROC_REQ        : out std_logic_vector        (PROC_NUM-1 downto 0);
        PROC_BUSY       : in  std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_VALID     : out std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_CODE      : out MsgPack_RPC.Code_Vector (PROC_NUM-1 downto 0);
        PARAM_LAST      : out std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_SHIFT     : in  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Response Interface
    -------------------------------------------------------------------------------
        PROC_RES_ID     : in  MsgPack_RPC.MsgID_Vector(PROC_NUM-1 downto 0);
        PROC_RES_CODE   : in  MsgPack_RPC.Code_Vector (PROC_NUM-1 downto 0);
        PROC_RES_VALID  : in  std_logic_vector        (PROC_NUM-1 downto 0);
        PROC_RES_LAST   : in  std_logic_vector        (PROC_NUM-1 downto 0);
        PROC_RES_READY  : out std_logic_vector        (PROC_NUM-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Server_Requester                                          --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Server_Requester
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        I_BYTES         : integer range 1 to 32 := 1;
        PROC_NUM        : integer := 1;
        MATCH_PHASE     : integer := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Byte Stream Input Interface
    -------------------------------------------------------------------------------
        I_DATA          : in  std_logic_vector(8*I_BYTES-1 downto 0);
        I_STRB          : in  std_logic_vector(  I_BYTES-1 downto 0);
        I_LAST          : in  std_logic := '0';
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Match I/F
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector     (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_RPC.Code_Type;
        MATCH_OK        : in  std_logic_vector        (PROC_NUM-1 downto 0);
        MATCH_NOT       : in  std_logic_vector        (PROC_NUM-1 downto 0);
        MATCH_SHIFT     : in  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Request I/F
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : out MsgPack_RPC.MsgID_Type;
        PROC_REQ        : out std_logic_vector        (PROC_NUM-1 downto 0);
        PROC_BUSY       : in  std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_VALID     : out std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_CODE      : out MsgPack_RPC.Code_Vector (PROC_NUM-1 downto 0);
        PARAM_LAST      : out std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_SHIFT     : in  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Error Response I/F
    -------------------------------------------------------------------------------
        ERROR_RES_ID    : out MsgPack_RPC.MsgID_Type;
        ERROR_RES_CODE  : out MsgPack_RPC.Code_Type;
        ERROR_RES_VALID : out std_logic;
        ERROR_RES_LAST  : out std_logic;
        ERROR_RES_READY : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Server_Responder                                          --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Server_Responder
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        O_BYTES         : integer range 1 to 32 := 1;
        RES_NUM         : integer := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Byte Stream Output Interface
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(8*O_BYTES-1 downto 0);
        O_STRB          : out std_logic_vector(  O_BYTES-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Response I/F
    -------------------------------------------------------------------------------
        RES_ID          : in  MsgPack_RPC.MsgID_Vector(RES_NUM-1 downto 0);
        RES_CODE        : in  MsgPack_RPC.Code_Vector (RES_NUM-1 downto 0);
        RES_VALID       : in  std_logic_vector        (RES_NUM-1 downto 0);
        RES_LAST        : in  std_logic_vector        (RES_NUM-1 downto 0);
        RES_READY       : out std_logic_vector        (RES_NUM-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Method_Main_with_Param                                    --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Method_Main_with_Param
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        NAME            : string;
        PARAM_NUM       : positive := 1;
        MATCH_PHASE     : positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_RPC.Code_Type;
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Call Request Interface
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : in  MsgPack_RPC.MsgID_Type;
        PROC_REQ        : in  std_logic;
        PROC_BUSY       : out std_logic;
        PROC_START      : out std_logic;
        PARAM_CODE      : in  MsgPack_RPC.Code_Type;
        PARAM_VALID     : in  std_logic;
        PARAM_LAST      : in  std_logic;
        PARAM_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Set Parameter Interface
    -------------------------------------------------------------------------------
        SET_PARAM_CODE  : out MsgPack_RPC.Code_Type;
        SET_PARAM_LAST  : out std_logic;
        SET_PARAM_VALID : out std_logic_vector        (PARAM_NUM-1 downto 0);
        SET_PARAM_ERROR : in  std_logic_vector        (PARAM_NUM-1 downto 0);
        SET_PARAM_DONE  : in  std_logic_vector        (PARAM_NUM-1 downto 0);
        SET_PARAM_SHIFT : in  MsgPack_RPC.Shift_Vector(PARAM_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Start/Busy
    -------------------------------------------------------------------------------
        RUN_REQ         : out std_logic;
        RUN_BUSY        : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return Interface
    -------------------------------------------------------------------------------
        RET_ID          : out MsgPack_RPC.MsgID_Type;
        RET_ERROR       : out std_logic;
        RET_START       : out std_logic;
        RET_BUSY        : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Method_Main_No_Param                                      --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Method_Main_No_Param
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        NAME            : string;
        MATCH_PHASE     : positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector(MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_RPC.Code_Type;
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Call Request Interface
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : in  MsgPack_RPC.MsgID_Type;
        PROC_REQ        : in  std_logic;
        PROC_BUSY       : out std_logic;
        PARAM_CODE      : in  MsgPack_RPC.Code_Type;
        PARAM_VALID     : in  std_logic;
        PARAM_LAST      : in  std_logic;
        PARAM_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Start/Busy
    -------------------------------------------------------------------------------
        RUN_REQ         : out std_logic;
        RUN_BUSY        : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return Interface
    -------------------------------------------------------------------------------
        RET_ID          : out MsgPack_RPC.MsgID_Type;
        RET_ERROR       : out std_logic;
        RET_START       : out std_logic;
        RET_BUSY        : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Method_Set_Param_Integer                                  --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Method_Set_Param_Integer
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
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
    -- MessagePack-RPC Method Set Parameter Interface
    -------------------------------------------------------------------------------
        SET_PARAM_CODE  : in  MsgPack_RPC.Code_Type;
        SET_PARAM_LAST  : in  std_logic;
        SET_PARAM_VALID : in  std_logic;
        SET_PARAM_ERROR : out std_logic;
        SET_PARAM_DONE  : out std_logic;
        SET_PARAM_SHIFT : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- Default Value Input Interface
    -------------------------------------------------------------------------------
        DEFAULT_VALUE   : in  std_logic_vector(VALUE_BITS-1 downto 0);
        DEFAULT_WE      : in  std_logic;
    -------------------------------------------------------------------------------
    -- Parameter Value Output Interface
    -------------------------------------------------------------------------------
        PARAM_VALUE     : out std_logic_vector(VALUE_BITS-1 downto 0);
        PARAM_WE        : out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Method_Return_Integer                                     --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Method_Return_Integer
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        VALUE_WIDTH     :  positive := 32;
        RETURN_UINT     :  boolean  := TRUE;
        RETURN_INT      :  boolean  := TRUE;
        RETURN_FLOAT    :  boolean  := TRUE;
        RETURN_BOOLEAN  :  boolean  := TRUE
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return Interface
    -------------------------------------------------------------------------------
        RET_ERROR       : in  std_logic;
        RET_START       : in  std_logic;
        RET_BUSY        : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Response Interface
    -------------------------------------------------------------------------------
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- Return Value
    -------------------------------------------------------------------------------
        VALUE           : in  std_logic_vector(VALUE_WIDTH-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Method_Return_Nil                                         --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Method_Return_Nil
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return Interface
    -------------------------------------------------------------------------------
        RET_ERROR       : in  std_logic;
        RET_START       : in  std_logic;
        RET_BUSY        : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Response Interface
    -------------------------------------------------------------------------------
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Method_Return_Code                                        --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Method_Return_Code
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return Interface
    -------------------------------------------------------------------------------
        RET_ERROR       : in  std_logic;
        RET_START       : in  std_logic;
        RET_BUSY        : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Response Interface
    -------------------------------------------------------------------------------
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- Object Encode Input Interface
    -------------------------------------------------------------------------------
        I_VALID         : in  std_logic;
        I_CODE          : in  MsgPack_RPC.Code_Type;
        I_LAST          : in  std_logic;
        I_READY         : out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Server_KVMap_Set_Value                                    --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Server_KVMap_Set_Value
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        NAME            : string;
        STORE_SIZE      : positive := 1;
        K_WIDTH         : positive := 1;
        MATCH_PHASE     : positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Match I/F
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_RPC.Code_Type;
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Call Request I/F
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : in  MsgPack_RPC.MsgID_Type;
        PROC_REQ        : in  std_logic;
        PROC_BUSY       : out std_logic;
        PROC_START      : out std_logic;
        PARAM_CODE      : in  MsgPack_RPC.Code_Type;
        PARAM_VALID     : in  std_logic;
        PARAM_LAST      : in  std_logic;
        PARAM_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Map Key Match I/F
    -------------------------------------------------------------------------------
        MAP_MATCH_REQ   : out std_logic_vector       (MATCH_PHASE-1 downto 0);
        MAP_MATCH_CODE  : out MsgPack_RPC.Code_Type;
        MAP_MATCH_OK    : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_MATCH_NOT   : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_MATCH_SHIFT : in  MsgPack_RPC.Shift_Vector(STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Map Value Object Decode Output I/F
    -------------------------------------------------------------------------------
        MAP_VALUE_VALID : out std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_CODE  : out MsgPack_RPC.Code_Type;
        MAP_VALUE_LAST  : out std_logic;
        MAP_VALUE_ERROR : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_DONE  : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_SHIFT : in  MsgPack_RPC.Shift_Vector(STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return I/F
    -------------------------------------------------------------------------------
        RES_ID          : out MsgPack_RPC.MsgID_Type;
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief MsgPack_RPC_Server_KVMap_Get_Value                                    --
-----------------------------------------------------------------------------------
component MsgPack_RPC_Server_KVMap_Get_Value
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        NAME            : string;
        STORE_SIZE      : positive := 1;
        K_WIDTH         : positive := 1;
        MATCH_PHASE     : positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Match I/F
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_RPC.Code_Type;
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Call Request I/F
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : in  MsgPack_RPC.MsgID_Type;
        PROC_REQ        : in  std_logic;
        PROC_BUSY       : out std_logic;
        PROC_START      : out std_logic;
        PARAM_CODE      : in  MsgPack_RPC.Code_Type;
        PARAM_VALID     : in  std_logic;
        PARAM_LAST      : in  std_logic;
        PARAM_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Map Key Match I/F
    -------------------------------------------------------------------------------
        MAP_MATCH_REQ   : out std_logic_vector       (MATCH_PHASE-1 downto 0);
        MAP_MATCH_CODE  : out MsgPack_RPC.Code_Type;
        MAP_MATCH_OK    : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_MATCH_NOT   : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_MATCH_SHIFT : in  MsgPack_RPC.Shift_Vector(STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Map Parameter Object Decode Output I/F
    -------------------------------------------------------------------------------
        MAP_PARAM_START : out std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_PARAM_VALID : out std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_PARAM_CODE  : out MsgPack_RPC.Code_Type;
        MAP_PARAM_LAST  : out std_logic;
        MAP_PARAM_ERROR : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_PARAM_DONE  : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_PARAM_SHIFT : in  MsgPack_RPC.Shift_Vector(STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Map Value Object Encode Input I/F
    -------------------------------------------------------------------------------
        MAP_VALUE_VALID : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_CODE  : in  MsgPack_RPC.Code_Vector (STORE_SIZE-1 downto 0);
        MAP_VALUE_LAST  : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_ERROR : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_READY : out std_logic_vector        (STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return I/F
    -------------------------------------------------------------------------------
        RES_ID          : out MsgPack_RPC.MsgID_Type;
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic
    );
end component;
end MsgPack_RPC_Components;
