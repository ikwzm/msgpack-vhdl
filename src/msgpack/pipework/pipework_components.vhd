-----------------------------------------------------------------------------------
--!     @file    pipework/pipework_components.vhd                                --
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
-----------------------------------------------------------------------------------
--! @brief MessagaPack Component Library Description                             --
-----------------------------------------------------------------------------------
package PipeWork_Components is
-----------------------------------------------------------------------------------
--! @brief REDUCER                                                               --
-----------------------------------------------------------------------------------
component REDUCER
    generic (
        WORD_BITS   : --! @brief WORD BITS :
                      --! １ワードのデータのビット数を指定する.
                      integer := 8;
        STRB_BITS   : --! @brief ENABLE BITS :
                      --! ワードデータのうち有効なデータであることを示す信号(STRB)
                      --! のビット数を指定する.
                      integer := 1;
        I_WIDTH     : --! @brief INPUT WORD WIDTH :
                      --! 入力側のデータのワード数を指定する.
                      integer := 1;
        O_WIDTH     : --! @brief OUTPUT WORD WIDTH :
                      --! 出力側のデータのワード数を指定する.
                      integer := 1;
        QUEUE_SIZE  : --! @brief QUEUE SIZE :
                      --! キューの大きさをワード数で指定する.
                      --! * QUEUE_SIZE=0を指定した場合は、キューの深さは自動的に
                      --!   O_WIDTH+I_WIDTH+I_WIDTH-1 に設定される.
                      --! * QUEUE_SIZE<O_WIDTH+I_WIDTH-1の場合は、キューの深さは
                      --!   自動的にO_WIDTH+I_WIDTH-1に設定される.
                      integer := 0;
        VALID_MIN   : --! @brief BUFFER VALID MINIMUM NUMBER :
                      --! VALID信号の配列の最小値を指定する.
                      integer := 0;
        VALID_MAX   : --! @brief BUFFER VALID MAXIMUM NUMBER :
                      --! VALID信号の配列の最大値を指定する.
                      integer := 0;
        O_VAL_SIZE  : --! @brief OUTPUT WORD VALID SIZE :
                      --! O_VAL 信号アサート時のキューに入っているワード数.
                      --! * キューに O_VAL_SIZE 以上のワード数が入っていると O_VAL 
                      --!   信号をアサートする.
                      --! * 互換性維持のため O_VAL_SIZE=0を指定した場合は、キューに
                      --!   O_WIDTH 以上のワード数が入っていると O_VAL 信号をアサー
                      --!   トする.
                      integer := 0;
        O_SHIFT_MIN : --! @brief OUTPUT SHIFT SIZE MINIMUM NUMBER :
                      --! O_SHIFT信号の配列の最小値を指定する.
                      integer := 1;
        O_SHIFT_MAX : --! @brief OUTPUT SHIFT SIZE MINIMUM NUMBER :
                      --! O_SHIFT信号の配列の最大値を指定する.
                      integer := 1;
        I_JUSTIFIED : --! @brief INPUT WORD JUSTIFIED :
                      --! 入力側の有効なデータが常にLOW側に詰められていることを
                      --! 示すフラグ.
                      --! * 常にLOW側に詰められている場合は、シフタが必要なくなる
                      --!   ため回路が簡単になる.
                      integer range 0 to 1 := 0;
        FLUSH_ENABLE: --! @brief FLUSH ENABLE :
                      --! FLUSH/I_FLUSHによるフラッシュ処理を有効にするかどうかを
                      --! 指定する.
                      --! * FLUSHとDONEとの違いは、DONEは最後のデータの出力時に
                      --!   キューの状態をすべてクリアするのに対して、
                      --!   FLUSHは最後のデータの出力時にSTRBだけをクリアしてVALは
                      --!   クリアしない.
                      --!   そのため次の入力データは、最後のデータの次のワード位置
                      --!   から格納される.
                      --! * フラッシュ処理を行わない場合は、0を指定すると回路が若干
                      --!   簡単になる.
                      integer range 0 to 1 := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK         : --! @brief CLOCK :
                      --! クロック信号
                      in  std_logic; 
        RST         : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブハイ.
                      in  std_logic;
        CLR         : --! @brief SYNCRONOUSE RESET :
                      --! 同期リセット信号.アクティブハイ.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 各種制御信号
    -------------------------------------------------------------------------------
        START       : --! @brief START :
                      --! 開始信号.
                      --! * この信号はOFFSETを内部に設定してキューを初期化する.
                      --! * 最初にデータ入力と同時にアサートしても構わない.
                      in  std_logic := '0';
        OFFSET      : --! @brief OFFSET :
                      --! 最初のワードの出力位置を指定する.
                      --! * START信号がアサートされた時のみ有効.
                      --! * O_WIDTH>I_WIDTHの場合、最初のワードデータを出力する際の
                      --!   オフセットを設定できる.
                      --! * 例えばWORD_BITS=8、I_WIDTH=1(1バイト入力)、O_WIDTH=4(4バイト出力)の場合、
                      --!   OFFSET="0000"に設定すると、最初に入力したバイトデータは
                      --!   1バイト目から出力される.    
                      --!   OFFSET="0001"に設定すると、最初に入力したバイトデータは
                      --!   2バイト目から出力される.    
                      --!   OFFSET="0011"に設定すると、最初に入力したバイトデータは
                      --!   3バイト目から出力される.    
                      --!   OFFSET="0111"に設定すると、最初に入力したバイトデータは
                      --!   4バイト目から出力される.    
                      in  std_logic_vector(O_WIDTH-1 downto 0) := (others => '0');
        DONE        : --! @brief DONE :
                      --! 終了信号.
                      --! * この信号をアサートすることで、キューに残っているデータ
                      --!   を掃き出す.
                      --!   その際、最後のワードと同時にO_DONE信号がアサートされる.
                      --! * FLUSH信号との違いは、FLUSH_ENABLEの項を参照.
                      in  std_logic := '0';
        FLUSH       : --! @brief FLUSH :
                      --! フラッシュ信号.
                      --! * この信号をアサートすることで、キューに残っているデータ
                      --!   を掃き出す.
                      --!   その際、最後のワードと同時にO_FLUSH信号がアサートされる.
                      --! * DONE信号との違いは、FLUSH_ENABLEの項を参照.
                      in  std_logic := '0';
        BUSY        : --! @brief BUSY :
                      --! ビジー信号.
                      --! * 最初にデータが入力されたときにアサートされる.
                      --! * 最後のデータが出力し終えたらネゲートされる.
                      out std_logic;
        VALID       : --! @brief QUEUE VALID FLAG :
                      --! キュー有効信号.
                      --! * 対応するインデックスのキューに有効なワードが入って
                      --!   いるかどうかを示すフラグ.
                      out std_logic_vector(VALID_MAX downto VALID_MIN);
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_ENABLE    : --! @brief INPUT ENABLE :
                      --! 入力許可信号.
                      --! * この信号がアサートされている場合、キューの入力を許可する.
                      --! * この信号がネゲートされている場合、I_RDY アサートされない.
                      in  std_logic := '1';
        I_DATA      : --! @brief INPUT WORD DATA :
                      --! ワードデータ入力.
                      in  std_logic_vector(I_WIDTH*WORD_BITS-1 downto 0);
        I_STRB      : --! @brief INPUT WORD ENABLE :
                      --! ワードストローブ信号入力.
                      in  std_logic_vector(I_WIDTH*STRB_BITS-1 downto 0);
        I_DONE      : --! @brief INPUT WORD DONE :
                      --! 最終ワード信号入力.
                      --! * 最後の力ワードデータ入であることを示すフラグ.
                      --! * 基本的にはDONE信号と同じ働きをするが、I_DONE信号は
                      --!   最後のワードデータを入力する際に同時にアサートする.
                      --! * I_FLUSH信号との違いはFLUSH_ENABLEの項を参照.
                      in  std_logic := '0';
        I_FLUSH     : --! @brief INPUT WORD FLUSH :
                      --! 最終ワード信号入力.
                      --! * 最後のワードデータ入力であることを示すフラグ.
                      --! * 基本的にはFLUSH信号と同じ働きをするが、I_FLUSH信号は
                      --!   最後のワードデータを入力する際に同時にアサートする.
                      --! * I_DONE信号との違いはFLUSH_ENABLEの項を参照.
                      in  std_logic := '0';
        I_VAL       : --! @brief INPUT WORD VALID :
                      --! 入力ワード有効信号.
                      --! * I_DATA/I_STRB/I_DONE/I_FLUSHが有効であることを示す.
                      --! * I_VAL='1'and I_RDY='1'でワードデータがキューに取り込まれる.
                      in  std_logic;
        I_RDY       : --! @brief INPUT WORD READY :
                      --! 入力レディ信号.
                      --! * キューが次のワードデータを入力出来ることを示す.
                      --! * I_VAL='1'and I_RDY='1'でワードデータがキューに取り込まれる.
                      out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_ENABLE    : --! @brief OUTPUT ENABLE :
                      --! 出力許可信号.
                      --! * この信号がアサートされている場合、キューの出力を許可する.
                      --! * この信号がネゲートされている場合、O_VAL アサートされない.
                      in  std_logic := '1';
        O_DATA      : --! @brief OUTPUT WORD DATA :
                      --! ワードデータ出力.
                      out std_logic_vector(O_WIDTH*WORD_BITS-1 downto 0);
        O_STRB      : --! @brief OUTPUT WORD ENABLE :
                      --! ワードストローブ信号出力.
                      out std_logic_vector(O_WIDTH*STRB_BITS-1 downto 0);
        O_DONE      : --! @brief OUTPUT WORD DONE :
                      --! 最終ワード信号出力.
                      --! * 最後のワードデータ出力であることを示すフラグ.
                      --! * O_FLUSH信号との違いはFLUSH_ENABLEの項を参照.
                      out std_logic;
        O_FLUSH     : --! @brief OUTPUT WORD FLUSH :
                      --! 最終ワード信号出力.
                      --! * 最後のワードデータ出力であることを示すフラグ.
                      --! * O_DONE信号との違いはFLUSH_ENABLEの項を参照.
                      out std_logic;
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      --! 出力ワード有効信号.
                      --! * O_DATA/O_STRB/O_DONE/O_FLUSHが有効であることを示す.
                      --! * O_VAL='1'and O_RDY='1'でワードデータがキューから取り除かれる.
                      out std_logic;
        O_RDY       : --! @brief OUTPUT WORD READY :
                      --! 出力レディ信号.
                      --! * キューから次のワードを取り除く準備が出来ていることを示す.
                      --! * O_VAL='1'and O_RDY='1'でワードデータがキューから取り除かれる.
                      in  std_logic;
        O_SHIFT     : --! @brief OUTPUT SHIFT SIZE :
                      --! 出力シフトサイズ信号.
                      --! * キューからワードを出力する際に、何ワード取り除くかを指定する.
                      --! * O_VAL='1' and O_RDY='1'の場合にのみこの信号は有効.
                      --! * 取り除くワードの位置に'1'をセットする.
                      --! * 例) O_SHIFT_MAX=3、O_SHIFT_MIN=0の場合、    
                      --!   O_SHIFT(3 downto 0)="1111" で4ワード取り除く.    
                      --!   O_SHIFT(3 downto 0)="0111" で3ワード取り除く.    
                      --!   O_SHIFT(3 downto 0)="0011" で2ワード取り除く.    
                      --!   O_SHIFT(3 downto 0)="0001" で1ワード取り除く.    
                      --!   O_SHIFT(3 downto 0)="0000" で取り除かない.    
                      --!   上記以外の値を指定した場合は動作を保証しない.
                      --! * 例) O_SHIFT_MAX=3、O_SHIFT_MIN=2の場合、    
                      --!   O_SHIFT(3 downto 2)="11" で4ワード取り除く.    
                      --!   O_SHIFT(3 downto 2)="01" で3ワード取り除く.    
                      --!   O_SHIFT(3 downto 2)="00" で2ワード取り除く.    
                      --!   上記以外の値を指定した場合は動作を保証しない.
                      --! * 例) O_SHIFT_MAX=1、O_SHIFT_MIN=1の場合、    
                      --!   O_SHIFT(1 downto 1)="1" で2ワード取り除く.    
                      --!   O_SHIFT(1 downto 1)="0" で1ワード取り除く.
                      --! * 例) O_SHIFT_MAX=0、O_SHIFT_MIN=0の場合、    
                      --!   O_SHIFT(0 downto 0)="1" で1ワード取り除く.    
                      --!   O_SHIFT(0 downto 0)="0" で取り除かない.
                      --! * 出力ワード数(O_WIDTH)分だけ取り除きたい場合は、
                      --!   O_SHIFT_MAX=O_WIDTH、O_SHIFT_MIN=O_WIDTH、
                      --!   O_SHIFT=(others => '0') としておくと良い.
                      in  std_logic_vector(O_SHIFT_MAX downto O_SHIFT_MIN) := (others => '0')
    );
end component;
-----------------------------------------------------------------------------------
--! @brief CHOPPER                                                               --
-----------------------------------------------------------------------------------
component CHOPPER
    -------------------------------------------------------------------------------
    -- ジェネリック変数
    -------------------------------------------------------------------------------
    generic (
        BURST       : --! @brief BURST MODE : 
                      --! バースト転送に対応するかを指定する.
                      --! * 1:バースト転送に対応する.
                      --!   0:バースト転送に対応しない.
                      --! * バースト転送に対応する場合は、CHOP信号をアサートする度に 
                      --!   PIECE_COUNT や各種出力信号が更新される.
                      --! * バースト転送に対応しない場合は、カウンタの初期値は１に設
                      --!   定され、CHOP信号が一回アサートされた時点でカウンタは停止
                      --!   する. つまり、最初のピースのサイズしか生成されない.
                      --! * 当然 BURST=0 の方が回路規模は小さくなる.
                      integer range 0 to 1 := 1;
        MIN_PIECE   : --! @brief MINIMUM PIECE SIZE :
                      --! １ピースの大きさの最小値を2のべき乗値で指定する.
                      --! * 例えば、大きさの単位がバイトの場合次のようになる.
                      --!   0=1バイト、1=2バイト、2=4バイト、3=8バイト
                      integer := 6;
        MAX_PIECE   : --! @brief MAXIMUM PIECE SIZE :
                      --! １ピースの大きさの最大値を2のべき乗値で指定する.
                      --! * 例えば、大きさの単位がバイトの場合次のようになる.
                      --!   0=1バイト、1=2バイト、2=4バイト、3=8バイト
                      --! * MAX_PIECE > MIN_PIECE の場合、１ピースの大きさを 
                      --!   SEL 信号によって選択することができる.
                      --!   SEL信号の対応するビットを'1'に設定して他のビットを'0'に
                      --!   設定することによって１ピースの大きさを指定する.
                      --! * MAX_PIECE = MIN_PIECE の場合、１ピースの大きさは 
                      --!   MIN_PIECEの値になる.
                      --!   この場合は SEL 信号は使用されない.
                      --! * MAX_PIECE と MIN_PIECE の差が大きいほど、回路規模は
                      --!   大きくなる。
                      integer := 6;
        MAX_SIZE    : --! @brief MAXIMUM SIZE :
                      --! 想定している最大の大きさを2のべき乗値で指定する.
                      --! * この回路内で、MAX_SIZE-MIN_PIECEのビット幅のカウンタを
                      --!   生成する。
                      integer := 9;
        ADDR_BITS   : --! @brief BLOCK ADDRESS BITS :
                      --! ブロックの先頭アドレスを指定する信号(ADDR信号)の
                      --! ビット幅を指定する.
                      integer := 9;
        SIZE_BITS   : --! @brief BLOCK SIZE BITS :
                      --! ブロックの大きさを指定する信号(SIZE信号)のビット幅を
                      --! 指定する.
                      integer := 9;
        COUNT_BITS  : --! @brief OUTPUT COUNT BITS :
                      --! 出力するカウンタ信号(COUNT)のビット幅を指定する.
                      --! * 出力するカウンタのビット幅は、想定している最大の大きさ
                      --!   (MAX_SIZE)-１ピースの大きさの最小値(MIN_PIECE)以上で
                      --!   なければならない.
                      --! * カウンタ信号(COUNT)を使わない場合は、エラボレーション時
                      --!   にエラーが発生しないように1以上の値を指定しておく.
                      integer := 9;
        PSIZE_BITS  : --! @brief OUTPUT PIECE SIZE BITS :
                      --! 出力するピースサイズ(PSIZE,NEXT_PSIZE)のビット幅を指定する.
                      --! * ピースサイズのビット幅は、MAX_PIECE(１ピースのサイズを
                      --!   表現できるビット数)以上でなければならない.
                      integer := 9;
        GEN_VALID   : --! @brief GENERATE VALID FLAG :
                      --! ピース有効信号(VALID/NEXT_VALID)を生成するかどうかを指定する.
                      --! * GEN_VALIDが０以外の場合は、ピース有効信号を生成する.
                      --! * GEN_VALIDが０の場合は、ピース有効信号はALL'1'になる.
                      --! * GEN_VALIDが０以外でも、この回路の上位階層で
                      --!   ピース有効をopenにしても論理上は問題ないが、
                      --!   論理合成ツールによっては、コンパイルに膨大な時間を
                      --!   要することがある.
                      --!   その場合はこの変数を０にすることで解決出来る場合がある.
                      integer range 0 to 1 := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK         : --! @brief CLOCK :
                      --! クロック信号
                      in  std_logic; 
        RST         : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブハイ.
                      in  std_logic;
        CLR         : --! @brief SYNCRONOUSE RESET :
                      --! 同期リセット信号.アクティブハイ.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 各種初期値
    -------------------------------------------------------------------------------
        ADDR        : --! @brief BLOCK ADDRESS :
                      --! ブロックの先頭アドレス.
                      --! * LOAD信号のアサート時に内部に保存される.
                      --! * 入力はADDR_BITSで示されるビット数あるが、実際に使用され
                      --!   るのは、1ピース分の下位ビットだけ.
                      in  std_logic_vector(ADDR_BITS-1 downto 0);
        SIZE        : --! @brief BLOCK SIZE :
                      --! ブロックの大きさ.
                      --! * LOAD信号のアサート時に内部に保存される.
                      in  std_logic_vector(SIZE_BITS-1 downto 0);
        SEL         : --! @brief PIECE SIZE SELECT :
                      --! １ピースの大きさを選択するための信号.
                      --! * LOAD信号のアサート時に内部に保存される.
                      --! * １ピースの大きさに対応するビットのみ'1'をセットし、他の
                      --!   ビットは'0'をセットすることで１ピースの大きさを選択する.
                      --! * もしSEL信号のうち複数のビットに'1'が設定されていた場合は
                      --!   もっとも最小値に近い値(MIN_PIECEの値)が選ばれる。
                      --! * この信号は MAX_PIECE > MIN_PIECE の場合にのみ使用される.
                      --! * この信号は MAX_PIECE = MIN_PIECE の場合は無視される.
                      in  std_logic_vector(MAX_PIECE downto MIN_PIECE);
        LOAD        : --! @brief LOAD :
                      --! ADDR,SIZE,SELを内部にロードするための信号.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 制御信号
    -------------------------------------------------------------------------------
        CHOP        : --! @brief CHOP ENABLE :
                      --! ブロックをピースに分割する信号.
                      --! * この信号のアサートによって、ピースカウンタ、各種フラグ、
                      --!   ピースサイズを更新され、次のクロックでこれらの信号が
                      --!   出力される.
                      --! * LOAD信号と同時にアサートされた場合はLOADの方が優先され、
                      --!   CHOP信号は無視される.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- ピースカウンタ/フラグ出力
    -------------------------------------------------------------------------------
        COUNT       : --! @brief PIECE COUNT :
                      --! 残りのピースの数-1を示す.
                      --! * CHOP信号のアサートによりカウントダウンする.
                      out std_logic_vector(COUNT_BITS-1 downto 0);
        NONE        : --! @brief NONE PIECE FLAG :
                      --! 残りのピースの数が０になったことを示すフラグ.
                      --! * COUNT = (others => '1') で'1'が出力される.
                      out std_logic;
        LAST        : --! @brief LAST PIECE FLAG :
                      --! 残りのピースの数が１になったことを示すフラグ.
                      --! * COUNT = (others => '0') で'1'が出力される.
                      --! * 最後のピースであることを示す.
                      out std_logic;
        NEXT_NONE   : --! @brief NONE PIECE FLAG(NEXT CYCLE) :
                      --! 次のクロックで残りのピースの数が０になることを示すフラグ.
                      out std_logic;
        NEXT_LAST   : --! @brief LAST PIECE FLAG(NEXT CYCYE) :
                      --! 次のクロックで残りのピースの数が１になることを示すフラグ.
                      out std_logic;
    -------------------------------------------------------------------------------
    -- ピースサイズ(1ピースの容量)出力
    -------------------------------------------------------------------------------
        PSIZE       : --! @brief PIECE SIZE :
                      --! 現在のピースの大きさを示す.
                      out std_logic_vector(PSIZE_BITS-1 downto 0);
        NEXT_PSIZE  : --! @brief PIECE SIZE(NEXT CYCLE)
                      --! 次のクロックでのピースの大きさを示す.
                      out std_logic_vector(PSIZE_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- ピース有効出力
    -------------------------------------------------------------------------------
        VALID       : --! @brief PIECE VALID FLAG :
                      --! ピース有効信号.
                      --! * 例えば、ADDR=0x0002、SIZE=11、１ピースのサイズ=4の場合、
                      --!   "1100"、"1111"、"1111"、"0001" を生成する.
                      --! * GEN_VALIDが０以外の場合にのみ有効な値を生成する.
                      --! * GEN_VALIDが０の場合は常に ALL'1' を生成する.
                      out std_logic_vector(2**(MAX_PIECE)-1 downto 0);
        NEXT_VALID  : --! @brief PIECE VALID FALG(NEXT CYCLE)
                      --! 次のクロックでのピース有効信号
                      out std_logic_vector(2**(MAX_PIECE)-1 downto 0)
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QUEUE_REGISTER                                                        --
-----------------------------------------------------------------------------------
component QUEUE_REGISTER
    -------------------------------------------------------------------------------
    -- ジェネリック変数
    -------------------------------------------------------------------------------
    generic (
        QUEUE_SIZE  : --! @brief QUEUE SIZE :
                      --! キューの大きさをワード数で指定する.
                      integer := 1;
        DATA_BITS   : --! @brief DATA BITS :
                      --! データ(I_DATA/O_DATA/Q_DATA)のビット幅を指定する.
                      integer :=  32;
        LOWPOWER    : --! @brief LOW POWER MODE :
                      --! キューのレジスタに不必要なロードを行わないことにより、
                      --! レジスタが不必要にトグルすることを防いで消費電力を
                      --! 下げるようにする.
                      --! ただし、回路が若干増える.
                      integer range 0 to 1 := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK         : --! @brief CLOCK :
                      --! クロック信号
                      in  std_logic; 
        RST         : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブハイ.
                      in  std_logic;
        CLR         : --! @brief SYNCRONOUSE RESET :
                      --! 同期リセット信号.アクティブハイ.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側
    -------------------------------------------------------------------------------
        I_DATA      : --! @brief INPUT DATA  :
                      --! 入力データ信号.
                      in  std_logic_vector(DATA_BITS-1 downto 0);
        I_VAL       : --! @brief INPUT DATA VALID :
                      --! 入力データ有効信号.
                      in  std_logic;
        I_RDY       : --! @brief INPUT READY :
                      --! 入力可能信号.
                      --! キューが空いていて、入力データを受け付けることが可能で
                      --! あることを示す信号.
                      out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側
    -------------------------------------------------------------------------------
        O_DATA      : --! @brief OUTPUT DATA :
                      --! 出力データ.
                      out std_logic_vector(DATA_BITS-1 downto 0);
        O_VAL       : --! @brief OUTPUT DATA VALID :
                      --! キューレジスタに有効なデータが入っている事を示すフラグ.
                      --! * キューレジスタは1〜QUEUE_SIZEまであるが、対応する位置の
                      --!   フラグが'1'ならば有効なデータが入っている事を示す.
                      --! * この出力信号の範囲が1からではなく0から始まっている事に
                      --!   注意. これはQUEUE_SIZE=0の場合に対応するため.
                      --!   QUEUE_SIZE>0の場合は、O_VAL(0)はO_VAL(1)と同じ.
                      out std_logic_vector(QUEUE_SIZE  downto 0);
        Q_DATA      : --! @brief OUTPUT REGISTERD DATA :
                      --! レジスタ出力の出力データ.
                      --! 出力データ(O_DATA)をクロックで叩いたもの.
                      out std_logic_vector(DATA_BITS-1 downto 0);
        Q_VAL       : --! @brief OUTPUT REGISTERD DATA VALID :
                      --! キューレジスタに有効なデータが入っている事を示すフラグ.
                      --! O_VALをクロックで叩いたもの.
                      --! * キューレジスタは1〜QUEUE_SIZEまであるが、対応する位置の
                      --!   フラグが'1'ならば有効なデータが入っている事を示す.
                      --! * この出力信号の範囲が1からではなく0から始まっている事に
                      --!   注意. これはQUEUE_SIZE=0の場合に対応するため.
                      --!   QUEUE_SIZE>0の場合は、Q_VAL(0)はQ_VAL(1)と同じ.
                      out std_logic_vector(QUEUE_SIZE  downto 0);
        Q_RDY       : --! @brief OUTPUT READY :
                      --! 出力可能信号.
                      in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QUEUE_ARBITER                                                         --
-----------------------------------------------------------------------------------
component QUEUE_ARBITER
    generic (
        MIN_NUM     : --! @brief REQUEST MINIMUM NUMBER :
                      --! リクエストの最小番号を指定する.
                      integer := 0;
        MAX_NUM     : --! @brief REQUEST MAXIMUM NUMBER :
                      --! リクエストの最大番号を指定する.
                      integer := 7
    );
    port (
        CLK         : --! @brief CLOCK :
                      --! クロック信号
                      in  std_logic; 
        RST         : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブハイ.
                      in  std_logic;
        CLR         : --! @brief SYNCRONOUSE RESET :
                      --! 同期リセット信号.アクティブハイ.
                      in  std_logic;
        ENABLE      : --! @brief ARBITORATION ENABLE :
                      --! この調停回路を有効にするかどうかを指定する.
                      --! * 幾つかの調停回路を組み合わせて使う場合、設定によっては
                      --!  この調停回路の出力を無効にしたいことがある.
                      --!  その時はこの信号を'0'にすることで簡単に出来る.
                      --! * ENABLE='1'でこの回路は調停を行う.
                      --! * ENABLE='0'でこの回路は調停を行わない.
                      --!   この場合REQUEST信号に関係なREQUEST_OおよびGRANTは'0'になる.
                      --!   リクエストキューの中身は破棄される.
                      in  std_logic := '1';
        REQUEST     : --! @brief REQUEST INPUT :
                      --! リクエスト入力.
                      in  std_logic_vector(MIN_NUM to MAX_NUM);
        GRANT       : --! @brief GRANT OUTPUT :
                      --! 調停結果出力.
                      out std_logic_vector(MIN_NUM to MAX_NUM);
        GRANT_NUM   : --! @brief GRANT NUMBER :
                      --! 許可番号.
                      --! * ただしリクエストキューに次の要求が無い場合でも、
                      --!   なんらかの番号を出力してしまう.
                      out integer   range  MIN_NUM to MAX_NUM;
        REQUEST_O   : --! @brief REQUEST OUTOUT :
                      --! リクエストキューに次の要求があることを示す信号.
                      --! * VALIDと異なり、リクエストキューに次の要求があっても、
                      --!   対応するREQUEST信号が'0'の場合はアサートされない.
                      out std_logic;
        VALID       : --! @brief REQUEST QUEUE VALID :
                      --! リクエストキューに次の要求があることを示す信号.
                      --! * REQUEST_Oと異なり、リスエストキューに次の要求があると
                      --!   対応するREQUEST信号の状態に関わらずアサートされる.
                      out std_logic;
        SHIFT       : --! @brief REQUEST QUEUE SHIFT :
                      --! リクエストキューの先頭からリクエストを取り除く信号.
                      in  std_logic
    );
end component;
end PipeWork_Components;
