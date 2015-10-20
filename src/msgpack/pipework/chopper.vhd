-----------------------------------------------------------------------------------
--!     @file    chopper.vhd
--!     @brief   CHOPPER MODULE :
--!              先頭アドレス(ADDR信号)と容量(SIZE信号)で表されたブロックを、
--!              指定された単位(SEL信号およびMIN_PIECE変数、MAX_PIECE変数)のピース
--!              に分割するモジュール.
--!     @version 1.5.8
--!     @date    2015/5/19
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2012-2015 Ichiro Kawazome
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
-----------------------------------------------------------------------------------
--! @brief   CHOPPER :
--!          先頭アドレス(ADDR信号)と容量(SIZE信号)で表されたブロックを、
--!          指定された単位(SEL信号およびMIN_PIECE変数、MAX_PIECE変数)のピースに
--!          分割するモジュール.
--!        * 例1) ADDR=0x0002、SIZE=11、１ピースのサイズ=4の場合、
--!          2、4、4、1のサイズのピースに分割します.
--!        * 例2) ADDR=0x0048、SIZE=0x400、１ピースのサイズ=0x100の場合、
--!          0x0B8、0x100、0x100、0x100、0x048のサイズのピースに分割します.
--!        * ついでにピース有効信号(１ピースのうちどの部分が有効かを示す信号)も出力
--!          します.
--!          例えば、ADDR=0x0002、SIZE=11、１ピースのサイズ=4の場合、
--!          "1100"、"1111"、"1111"、"0001" を生成します.
--!          機能的には別モジュールでも良かったのですが、このモジュールで生成する
--!          ことにより回路が削減できるため、一緒にしました.
-----------------------------------------------------------------------------------
entity  CHOPPER is
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
end CHOPPER;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of CHOPPER is
    -------------------------------------------------------------------------------
    -- ブロックの先頭アドレス(ADDR)/ブロックのサイズ(SIZE)を扱い易いように内部形式に
    -- 変換した信号
    -------------------------------------------------------------------------------
    signal    block_size        : unsigned(MAX_SIZE downto 0);
    signal    block_size_dec    : unsigned(MAX_SIZE downto 0);
    signal    block_addr_top    : unsigned(MAX_SIZE downto 0);
    signal    block_addr_last   : unsigned(MAX_SIZE downto 0);
    -------------------------------------------------------------------------------
    -- 残りピース数をカウントしているカウンタおよび各種フラグ関連の信号
    -------------------------------------------------------------------------------
    constant  PIECE_COUNT_BITS  : integer := MAX_SIZE - MIN_PIECE;
    signal    curr_piece_count  : unsigned(PIECE_COUNT_BITS downto 0);
    signal    init_piece_count  : unsigned(PIECE_COUNT_BITS downto 0);
    signal    next_piece_count  : unsigned(PIECE_COUNT_BITS downto 0);
    signal    curr_piece_last   : boolean;
    signal    curr_piece_none   : boolean;
    signal    next_piece_last   : boolean;
    signal    next_piece_none   : boolean;
    signal    init_piece_last   : boolean;
    signal    init_piece_none   : boolean;
    -------------------------------------------------------------------------------
    -- 分割された１ピースのサイズを生成するための信号
    -------------------------------------------------------------------------------
    signal    curr_piece_size   : unsigned(MAX_PIECE downto 0);
    signal    next_piece_size   : unsigned(MAX_PIECE downto 0);
    signal    last_piece_size   : unsigned(MAX_PIECE downto 0);
    signal    max_piece_size    : unsigned(MAX_PIECE downto 0);
    signal    max_piece_size_q  : unsigned(MAX_PIECE downto 0);
    -------------------------------------------------------------------------------
    -- SEL信号から１ピースのサイズを整数値に変換した信号
    -------------------------------------------------------------------------------
    signal    sel_piece         : integer range MIN_PIECE to MAX_PIECE;
begin
    -------------------------------------------------------------------------------
    -- LOAD = '1' の時に ADDR または SIZE に不定があった場合は警告を出力するための
    -- プロセス。
    -------------------------------------------------------------------------------
    process (CLK) 
        variable  u_addr :  unsigned(ADDR_BITS-1 downto 0);
        variable  u_size :  unsigned(SIZE_BITS-1 downto 0);
    begin
        if (CLK'event and CLK = '1') then
            if (LOAD = '1') then
                u_addr := 0 + unsigned(ADDR);
                u_size := 0 + unsigned(SIZE);
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- sel_piece : SEL信号から１ピースのバイト数を整数値に変換したした信号.
    --             もしSEL信号のうち複数のビットに'1'が設定されていた場合は、
    --             もっとも最小値に近い値(MIN_PIECEの値)が選ばれる.
    -------------------------------------------------------------------------------
    process (SEL) 
        variable n : integer range MIN_PIECE to MAX_PIECE;
    begin
        n := MIN_PIECE;            
        if (MIN_PIECE < MAX_PIECE) then
            for i in MIN_PIECE to MAX_PIECE loop
                if (SEL(i) = '1') then
                    n := i;
                    exit;
                end if;
            end loop;
        end if;
        sel_piece <= n;
    end process;
    -------------------------------------------------------------------------------
    -- block_size     : 入力サイズ信号(SIZE)を、後々使い易いように unsigned 形式に
    --                  変換して、ビット長を MAX_SIZE で指定されている長さまで
    --                  ０拡張しておく.
    -- block_size_dec : block_size から、さらに1を引いておく.
    -------------------------------------------------------------------------------
    process (SIZE) 
        variable u_size : unsigned(block_size'range);
    begin
        u_size := RESIZE(TO_01(unsigned(SIZE),'0'),u_size'length);
        block_size     <= u_size;
        block_size_dec <= u_size - 1;
    end process;
    -------------------------------------------------------------------------------
    -- block_addr_top : 入力アドレス信号(ADDR)のうち、１ピース分のアドレスだけ抽出
    --                  して unsigned 形式に変換して、ビット長を MAX_SIZE で指定さ
    --                  れている長さまで０拡張しておく.
    -------------------------------------------------------------------------------
    process (ADDR, sel_piece)
        variable u_addr : unsigned(block_addr_top'range);
    begin
        for i in block_addr_top'range loop
            if (i < ADDR_BITS and i < sel_piece and MIN_PIECE < MAX_PIECE) or
               (i < ADDR_BITS and i < MIN_PIECE and MIN_PIECE = MAX_PIECE) then
                u_addr(i) := ADDR(i);
            else
                u_addr(i) := '0';
            end if;
        end loop;
        block_addr_top <= TO_01(u_addr,'0');
    end process;
    -------------------------------------------------------------------------------
    -- block_addr_last : block_addr_top に block_size_dec を加算して
    --                   ブロックの最終アドレスを計算する.
    -------------------------------------------------------------------------------
    block_addr_last <= block_addr_top + ('0' & block_size_dec(block_size_dec'left-1 downto 0));
    -------------------------------------------------------------------------------
    -- init_piece_count : piece_count の初期値.
    --                    block_addr_last を sel_piece 分だけ右にシフトすることに
    --                    よって計算される.
    -- init_piece_last  : init_piece_count = 0 であることを示すフラグ.
    -- init_piece_none  : block_size       = 0 であることを示すフラグ.
    -------------------------------------------------------------------------------
    process (block_addr_last, SEL)
        type     COUNT_VECTOR is array (INTEGER range <>) 
                              of unsigned(PIECE_COUNT_BITS downto 0);
        variable count_vec     : COUNT_VECTOR(MIN_PIECE to MAX_PIECE);
        variable count_val     : unsigned(PIECE_COUNT_BITS downto 0);
        variable non_0_vec     : std_logic_vector(MIN_PIECE to MAX_PIECE);
        variable non_0_val     : std_logic;
    begin
        for i in MIN_PIECE to MAX_PIECE loop
            non_0_vec(i) := '0';
            for j in 0 to PIECE_COUNT_BITS loop
                if (i+j <= block_addr_last'left) then 
                    count_vec(i)(j) := block_addr_last(i+j);
                    non_0_vec(i)    := block_addr_last(i+j) or non_0_vec(i);
                else
                    count_vec(i)(j) := '0';
                end if;
            end loop;
        end loop;
        count_val := count_vec(MIN_PIECE);
        non_0_val := non_0_vec(MIN_PIECE);
        if (MIN_PIECE < MAX_PIECE) then
            for i in MIN_PIECE to MAX_PIECE loop
                if (SEL(i) = '1') then
                    count_val := count_vec(i);
                    non_0_val := non_0_vec(i);
                    exit;
                end if;
            end loop;
        end if;
        init_piece_count <= count_val;
        init_piece_last  <= (non_0_val = '0');
    end process;
    init_piece_none <= (block_size_dec(block_size_dec'left) = '1');
    -------------------------------------------------------------------------------
    -- next_piece_count : 次のクロックでのピースカウンタの値
    -- next_piece_none  : 次のクロックでのカウンタ終了信号
    -- next_piece_last  : 次のクロックでのカウンタ最終信号
    -------------------------------------------------------------------------------
    PCOUNT_NEXT: process (init_piece_count, init_piece_none, init_piece_last, LOAD,  
                          curr_piece_count, curr_piece_none, curr_piece_last, CHOP)
        variable piece_count_dec : unsigned(curr_piece_count'left+1 downto curr_piece_count'right);
    begin
        if    (LOAD = '1') then
            if    (init_piece_none) then
                next_piece_count <= (others => '1');
                next_piece_none  <= TRUE;
                next_piece_last  <= FALSE;
            elsif (BURST = 1) then
                next_piece_count <= init_piece_count;
                next_piece_none  <= FALSE;
                next_piece_last  <= init_piece_last;
            else
                next_piece_count <= (others => '0');
                next_piece_none  <= FALSE;
                next_piece_last  <= TRUE;
            end if;
        elsif (CHOP = '1' and curr_piece_none = FALSE) then
            if (BURST = 1) then
                piece_count_dec  := RESIZE(curr_piece_count, piece_count_dec'length) - 1;
                next_piece_count <= piece_count_dec(next_piece_count'range);
                next_piece_none  <= (piece_count_dec(piece_count_dec'left) = '1');
                next_piece_last  <= (piece_count_dec = 0);
            else
                next_piece_count <= (others => '1');
                next_piece_none  <= TRUE;
                next_piece_last  <= FALSE;
            end if;
        else
                next_piece_count <= curr_piece_count;
                next_piece_none  <= curr_piece_none;
                next_piece_last  <= curr_piece_last;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- curr_piece_count : ピースカウンタ
    -- curr_piece_none  : ピースカウンタ終了信号(curr_piece_count = 0)
    -- curr_piece_last  : ピースカウンタ最終信号(curr_piece_count = 1)
    -------------------------------------------------------------------------------
    PCOUNT_REGS: process (CLK, RST) begin
        if (RST = '1') then
                curr_piece_count <= (others => '1');
                curr_piece_none  <= TRUE;
                curr_piece_last  <= FALSE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_piece_count <= (others => '1');
                curr_piece_none  <= TRUE;
                curr_piece_last  <= FALSE;
            else
                curr_piece_count <= next_piece_count;
                curr_piece_none  <= next_piece_none;
                curr_piece_last  <= next_piece_last;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- max_piece_size   : ピース毎に転送するバイト数の最大値
    --                    MIN_PIECE=MAX_PIECEの場合は、2**MIN_PIECE の固定値とな
    --                    り、回路規模は少ない。
    --                    MIN_PIECE<MAX_PIECEの場合は、SEL信号により指定された１
    --                    ピース毎のバイト数となる。
    -------------------------------------------------------------------------------
    process (SEL, LOAD, max_piece_size_q) 
        variable max : unsigned(max_piece_size'range);
    begin
        if (MIN_PIECE < MAX_PIECE) then
            if (LOAD = '1') then
                max := TO_UNSIGNED(2**MIN_PIECE, max_piece_size'length);
                for i in MIN_PIECE to MAX_PIECE loop
                    if (SEL(i) = '1') then
                        max := TO_UNSIGNED(2**i, max_piece_size'length);
                        exit;
                    end if;
                end loop;
                max_piece_size <= max;
            else
                max_piece_size <= TO_01(max_piece_size_q,'0');
            end if;
        else
                max_piece_size <= TO_UNSIGNED(2**MIN_PIECE, max_piece_size'length);
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- max_piece_size_q : ピース毎に転送するバイト数の最大値を LOAD 信号ネゲート
    --                    後も保持しておく信号
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                max_piece_size_q <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                max_piece_size_q <= (others => '0');
            else
                max_piece_size_q <= max_piece_size;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- next_piece_size : 次のクロックでのピース毎に転送するサイズ
    -------------------------------------------------------------------------------
    PSIZE_NEXT: process (curr_piece_size, max_piece_size , last_piece_size,
                         init_piece_none, init_piece_last, block_addr_top , LOAD,
                         next_piece_none, next_piece_last, block_size     , CHOP) begin
        if    (LOAD = '1') then
            if    (init_piece_none) then
                next_piece_size <= (others => '0');
            elsif (init_piece_last) then
                next_piece_size <= block_size(next_piece_size'range);
            else
                next_piece_size <= max_piece_size - block_addr_top(next_piece_size'range);
            end if;
        elsif (CHOP = '1') then
            if    (next_piece_none or BURST = 0) then
                next_piece_size <= (others => '0');
            elsif (next_piece_last) then
                next_piece_size <= last_piece_size;
            else
                next_piece_size <= max_piece_size;
            end if;
        else
                next_piece_size <= curr_piece_size;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- curr_piece_size : ピース毎に転送するサイズ
    -------------------------------------------------------------------------------
    PSIZE_REGS: process (CLK, RST) begin
        if (RST = '1') then
                curr_piece_size <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_piece_size <= (others => '0');
            else
                curr_piece_size <= next_piece_size;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- last_piece_size : 最終ピースでのバイト数
    -------------------------------------------------------------------------------
    PSIZE_LAST: process (CLK, RST) 
        variable lo_block_addr_last : unsigned(MAX_PIECE downto 0);
    begin
        if (RST = '1') then
            last_piece_size <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                last_piece_size <= (others => '0');
            elsif (LOAD = '1') then
                for i in 0 to MAX_PIECE loop
                    if (i < sel_piece and MIN_PIECE < MAX_PIECE) or
                       (i < MIN_PIECE and MIN_PIECE = MAX_PIECE) then
                        lo_block_addr_last(i) := block_addr_last(i);
                    else
                        lo_block_addr_last(i) := '0';
                    end if;
                end loop;
                last_piece_size <= lo_block_addr_last + 1;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- ピース有効信号の生成
    -------------------------------------------------------------------------------
    VALID_GEN_T: if (GEN_VALID /= 0) generate
        signal    curr_piece_valid   : std_logic_vector(VALID'range);
        signal    next_piece_valid   : std_logic_vector(VALID'range);
        signal    piece_valid_1st    : std_logic_vector(VALID'range);
        signal    piece_valid_last   : std_logic_vector(VALID'range);
        signal    piece_valid_last_q : std_logic_vector(VALID'range);
        signal    piece_valid_mask   : std_logic_vector(VALID'range);
    begin
        ---------------------------------------------------------------------------
        -- next_piece_valid : 次のクロックでのピース有効信号
        ---------------------------------------------------------------------------
        VALID_NEXT: process (curr_piece_valid,
                             piece_valid_1st, piece_valid_last, piece_valid_mask,
                             init_piece_none, init_piece_last, LOAD,
                             next_piece_none, next_piece_last, CHOP) begin
            if    (LOAD = '1') then
                if    (init_piece_none) then
                    next_piece_valid <= (others => '0');
                elsif (init_piece_last) then
                    next_piece_valid <= piece_valid_1st and piece_valid_last;
                else
                    next_piece_valid <= piece_valid_1st and piece_valid_mask;
                end if;
            elsif (CHOP = '1') then
                if    (next_piece_none or BURST = 0) then
                    next_piece_valid <= (others => '0');
                elsif (next_piece_last) then
                    next_piece_valid <= piece_valid_last;
                else
                    next_piece_valid <= piece_valid_mask;
                end if;
            else
                    next_piece_valid <= curr_piece_valid;
            end if;
        end process;
        ---------------------------------------------------------------------------
        -- curr_piece_valid : ピース有効信号
        ---------------------------------------------------------------------------
        VALID_REGS: process (CLK, RST) begin
            if (RST = '1') then
                    curr_piece_valid <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    curr_piece_valid <= (others => '0');
                else
                    curr_piece_valid <= next_piece_valid;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        -- piece_valid_mask : 指定された１ピース毎のバイト数分だけピース有効信号を
        --                    マスクするための信号
        ---------------------------------------------------------------------------
        VALID_MSK_COMB: process (max_piece_size)
            variable max : unsigned(MAX_PIECE downto 0);
        begin
            if (MAX_PIECE > MIN_PIECE) then
                max := TO_01(max_piece_size, '0');
                for i in piece_valid_mask'range loop
                    if (i < max) then
                        piece_valid_mask(i) <= '1';
                    else
                        piece_valid_mask(i) <= '0';
                    end if;
                end loop;
            else
                piece_valid_mask <= (others => '1');
            end if;
        end process;
        ---------------------------------------------------------------------------
        -- piece_valid_1st  : 開始ピースでのピース有効信号
        ---------------------------------------------------------------------------
        VALID_1ST_COMB: process (block_addr_top, sel_piece) 
            variable lo_block_addr_top : unsigned(MAX_PIECE downto 0);
        begin
            for i in 0 to MAX_PIECE loop
                if (i < sel_piece and MIN_PIECE < MAX_PIECE) or
                   (i < MIN_PIECE and MIN_PIECE = MAX_PIECE) then
                    lo_block_addr_top(i) := block_addr_top(i);
                else
                    lo_block_addr_top(i) := '0';
                end if;
            end loop;
            lo_block_addr_top := TO_01(lo_block_addr_top,'0');
            for i in piece_valid_1st'range loop
                if (i >= lo_block_addr_top) then
                    piece_valid_1st(i) <= '1';
                else
                    piece_valid_1st(i) <= '0';
                end if;
            end loop;
        end process;
        ---------------------------------------------------------------------------
        -- piece_valid_last : 最終ピースでのピース有効信号
        ---------------------------------------------------------------------------
        VALID_LAST_COMB: process (piece_valid_last_q, block_addr_last, sel_piece, LOAD) 
            variable lo_block_addr_last   : unsigned(MAX_PIECE downto 0);
        begin
            if (LOAD = '1') then
                for i in 0 to MAX_PIECE loop
                    if (i < sel_piece and MIN_PIECE < MAX_PIECE) or
                       (i < MIN_PIECE and MIN_PIECE = MAX_PIECE) then
                        lo_block_addr_last(i) := block_addr_last(i);
                    else
                        lo_block_addr_last(i) := '0';
                    end if;
                end loop;
                lo_block_addr_last := TO_01(lo_block_addr_last,'0');
                for i in piece_valid_last'range loop
                    if (i <= lo_block_addr_last) then
                        piece_valid_last(i) <= '1';
                    else
                        piece_valid_last(i) <= '0';
                    end if;
                end loop;
            else
                piece_valid_last <= piece_valid_last_q;
            end if;
        end process;
        ---------------------------------------------------------------------------
        --  piece_valid_last_q : 最終ピースでのピース有効の値を LOAD 信号ネゲート後
        --                       も保持しておく信号
        ---------------------------------------------------------------------------
        VALID_LAST_REGS: process (CLK, RST) begin
            if (RST = '1') then
                    piece_valid_last_q <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    piece_valid_last_q <= (others => '0');
                else
                    piece_valid_last_q <= piece_valid_last;
                end if;
            end if;
        end process;
        VALID      <= curr_piece_valid;
        NEXT_VALID <= next_piece_valid;
    end generate;
    VALID_GEN_F: if (GEN_VALID = 0) generate
        VALID      <= (others => '1');
        NEXT_VALID <= (others => '1');
    end generate;
    -------------------------------------------------------------------------------
    -- 各種出力信号の生成
    -------------------------------------------------------------------------------
    process (curr_piece_count, curr_piece_none) begin
        for i in COUNT'range loop
            if (i > curr_piece_count'high) then
                if (curr_piece_none) then
                    COUNT(i) <= '1';
                else
                    COUNT(i) <= '0';
                end if;
            else
                COUNT(i) <= curr_piece_count(i);
            end if;
        end loop;
    end process;
    NONE       <= '1' when (curr_piece_none) else '0';
    LAST       <= '1' when (curr_piece_last) else '0';
    NEXT_NONE  <= '1' when (next_piece_none) else '0';
    NEXT_LAST  <= '1' when (next_piece_last) else '0';
    PSIZE      <= std_logic_vector(RESIZE(curr_piece_size, PSIZE'length));
    NEXT_PSIZE <= std_logic_vector(RESIZE(next_piece_size, PSIZE'length));
end RTL;
