#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------
#
#       Version     :   0.0.9
#       Created     :   2016/6/18
#       File name   :   vhdl-arichiver.rb
#       Author      :   Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
#       Description :   複数のVHDLのソースコードを解析してパッケージの依存関係を
#                       調べて、ファイルをコンパイルする順番に並べて一つのファイル
#                       に結合するスクリプト.
#                       VHDL 言語としてアナライズしているわけでなく、たんなる文字
#                       列として処理していることに注意。
#
#---------------------------------------------------------------------------------
#
#       Copyright (C) 2014-2016 Ichiro Kawazome
#       All rights reserved.
# 
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions
#       are met:
# 
#         1. Redistributions of source code must retain the above copyright
#            notice, this list of conditions and the following disclaimer.
# 
#         2. Redistributions in binary form must reproduce the above copyright
#            notice, this list of conditions and the following disclaimer in
#            the documentation and/or other materials provided with the
#            distribution.
# 
#       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#       "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#       LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#       A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
#       OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#       SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#       LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#       DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#       THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#       OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
#---------------------------------------------------------------------------------
require 'optparse'
require 'find'
require 'set'
require 'yaml'
require_relative 'lib/pipework/vhdl-reader'
class VhdlArchiver
  #-------------------------------------------------------------------------------
  # initialize    :
  #-------------------------------------------------------------------------------
  def initialize
    @program_name      = "vhdl-archiver"
    @program_version   = "0.0.9"
    @program_id        = @program_name + " " + @program_version
    @library_name      = ""
    @verbose           = false
    @debug             = false
    @library_info      = Hash.new
    @use_entity_list   = Array.new
    @top_entity_list   = Array.new
    @opt               = OptionParser.new do |opt|
      opt.program_name = @program_name
      opt.version      = @program_version
      opt.on("--verbose"                        ){|val| @verbose = true                  }
      opt.on("--debug"                          ){|val| @debug   = true                  }
      opt.on("--all"                            ){|val| @library_name = :global          }
      opt.on("--library    LIBRARY_NAME"        ){|val| new_lib(val.upcase)              }
      opt.on("--use_entity ENTITY(ARCHITECHURE)"){|val| add_val(:use_entity       , val )}
      opt.on("--use        ENTITY(ARCHITECHURE)"){|val| add_val(:use_entity       , val )}
      opt.on("--top        ENTITY(ARCHITECHURE)"){|val| add_val(:top_unit         , val )}
      opt.on("--exclude    FILE_NAME"           ){|val| add_val(:exclude          , val )}
      opt.on("--print"                          ){|val| add_val(:print            , true)}
      opt.on("--execute    STRING"              ){|val| add_val(:execute          , val )}
      opt.on("--format     STRING"              ){|val| add_val(:format           , val )}
      opt.on("--output     FILE_NAME"           ){|val| add_val(:output_file_name , val )}
      opt.on("--archive    FILE_NAME"           ){|val| add_val(:archive_file_name, val )}
      opt.on("--config     FILE_NAME"           ){|val| read_config_file(val)            }
    end
    new_lib(:global)
    new_lib("WORK")
  end
  #-------------------------------------------------------------------------------
  # new_lib       :
  #-------------------------------------------------------------------------------
  def new_lib(name)
    @library_name = name
    if @library_info.key?(@library_name) == false
      @library_info[@library_name] = Hash.new
      @library_info[@library_name][:name             ] = name
      @library_info[@library_name][:replace_name     ] = nil
      @library_info[@library_name][:path_list        ] = Array.new
      @library_info[@library_name][:use_entity       ] = Hash.new
      @library_info[@library_name][:top_unit         ] = Array.new
      @library_info[@library_name][:exclude_path_list] = Array.new
      @library_info[@library_name][:output_file_name ] = nil
      @library_info[@library_name][:archive_file_name] = nil
      @library_info[@library_name][:execute          ] = nil
      @library_info[@library_name][:print            ] = nil
      @library_info[@library_name][:format           ] = '#{file_name}'
    else
      library_info = @library_info[@library_name]
      @library_info.delete(@library_name)
      @library_info[@library_name] = library_info
    end
  end
  #-------------------------------------------------------------------------------
  # add_val       :
  #-------------------------------------------------------------------------------
  def add_val(key,item)
    if @library_info.key?(@library_name)
      case key
      when :name              then
        @library_info[@library_name][:name             ] =  item
      when :print             then
        @library_info[@library_name][:print            ] =  item
      when :format             then
        @library_info[@library_name][:format           ] =  item
      when :execute             then
        @library_info[@library_name][:execute          ] =  item
      when :replace_name      then
        @library_info[@library_name][:replace_name     ] =  item
      when :output_file_name  then
        @library_info[@library_name][:output_file_name ] =  item
      when :archive_file_name then
        @library_info[@library_name][:archive_file_name] =  item
      when :exclude           then
        @library_info[@library_name][:exclude_path_list] << item
      when :path_list         then
        @library_info[@library_name][:path_list        ] << item
      when :use_entity        then
        if (add_use_entity(@library_name, item) == false)
          @use_entity_list << item
        end
      when :top_unit        then
        if (add_top_unit(@library_name, item) == false)
          @top_entity_list << item
        end
      else
      end
    end
  end
  #-------------------------------------------------------------------------------
  # add_use_entity :
  #-------------------------------------------------------------------------------
  def add_use_entity(default_library_name, item)
    unit_name = PipeWork::VHDL_Reader.parse_unit_name(item,0)
    return false if (unit_name == nil)
    return false if (unit_name.instance_of?(PipeWork::VHDL_Reader::EntityName) == false)
    if unit_name.library_name == nil
      unit_name.library_name = default_library_name
    end
    entity_name  = unit_name.name
    library_name = unit_name.library_name
    architecture = unit_name.arch_name
    return false if (@library_info.key?(library_name) == false)
    if (@library_info[library_name][:use_entity].key?(entity_name) == false)
      @library_info[library_name][:use_entity][entity_name] = Set.new
    end
    @library_info[library_name][:use_entity][entity_name] << architecture
    return true
  end
  #-------------------------------------------------------------------------------
  # add_top_unit :
  #-------------------------------------------------------------------------------
  def add_top_unit(default_library_name, item)
    unit_name = PipeWork::VHDL_Reader.parse_unit_name(item,0)
    return false if unit_name == nil
    if unit_name.library_name == nil
      unit_name.library_name = default_library_name
    end
    library_name = unit_name.library_name
    return false if (@library_info.key?(library_name) == false)
    @library_info[library_name][:top_unit] << unit_name
    return true
  end
  #-------------------------------------------------------------------------------
  # parse_options
  #-------------------------------------------------------------------------------
  def parse_options(argv)
    @opt.order(argv) do |path|
      add_val(:path_list, path)
    end
    @use_entity_list.each do |item|
      add_use_entity("WORK", item)
    end
    @top_entity_list.each do |item|
      add_top_unit("WORK", item)
    end
  end
  #-------------------------------------------------------------------------------
  # read_config_file   : 
  #-------------------------------------------------------------------------------
  def read_config_file(file_name)
    config_list   = YAML.load_file(file_name)
    global_config = Hash.new
    config_list.select{|config| config.key?("Global" )}.map do |config|
      global_config.merge!(config["Global"])
    end
    config_list.select{|config| config.key?("Library")}.map do |config|
      library_config = config["Library"]
      if library_config.key?("Name")
        name = library_config["Name"]
        new_lib(name.upcase)
        add_val(:name, name)
        add_config(global_config)
        add_config(library_config)
      end
    end
  end
  #-------------------------------------------------------------------------------
  # add_library_config : 
  #-------------------------------------------------------------------------------
  def add_config(config)
    if config.key?("Use") 
      config["Use"].each do |entity|
        add_val(:use_entity, entity)
      end
    end
    if config.key?("Top") 
      config["Top"].each do |entity|
        add_val(:top_unit  , entity)
      end
    end
    if config.key?("PathList") 
      config["PathList"].each do |entity|
        add_val(:path_list , entity)
      end
    end
    if config.key?("Exclude") 
      config["Exclude"].each do |entity|
        add_val(:exclude   , entity)
      end
    end
    if config.key?("Format") 
      add_val(:format, config["Format"])
    end
    if config.key?("Execute") 
      add_val(:execute, config["Execute"])
    end
    if config.key?("Output") 
      add_val(:output_file_name, config["Output"])
    end
    if config.key?("Archive") 
      add_val(:archive_file_name, config["Archive"])
    end
    if config.key?("Print") 
      add_val(:print, config["Print"])
    end
  end
  #-------------------------------------------------------------------------------
  # execute   : 
  #-------------------------------------------------------------------------------
  def execute
    #-----------------------------------------------------------------------------
    # @library_infoに格納された各ライブラリのパスに対して走査して unit_list を生成する.
    #-----------------------------------------------------------------------------
    unit_list = PipeWork::VHDL_Reader::LibraryUnitList.new
    unit_list.verbose = @verbose
    @library_info.each_key do |library_name|
      exclude_path_list = @library_info[library_name][:exclude_path_list]
      @library_info[library_name][:path_list].each do |path_name|
        unit_list.analyze_path(path_name, library_name, exclude_path_list)
      end
    end
    # unit_list.debug_print
    #-----------------------------------------------------------------------------
    # entity 対して architecture を指定されている場合は、指定された architecture
    # 以外 を unit_list から取り除く.
    #-----------------------------------------------------------------------------
    @library_info.each_key do |library_name|
      use_entity = @library_info[library_name][:use_entity]
      unit_list.reject! do |unit|
        (unit.type == :Architecture) and
        (unit.library_name == library_name) and
        (use_entity.key?(unit.name) == true) and
        (use_entity[unit.name].to_a.index(unit.arch_name) == nil)
      end
    end
    ## unit_list.debug_print
    #-----------------------------------------------------------------------------
    #
    #-----------------------------------------------------------------------------
    top_list = Array.new
    @library_info.each_key do |library_name|
      top_list.concat @library_info[library_name][:top_unit]
    end
    if top_list.size > 0 
      unit_list = unit_list.select_bound_unit(top_list)
    end
    # unit_list.debug_print
    #-----------------------------------------------------------------------------
    # 出来上がった unit_list を元に unit_file_list を生成する.
    #-----------------------------------------------------------------------------
    unit_file_list = PipeWork::VHDL_Reader::UnitFileList.new
    unit_file_list.add_unit_list(unit_list)
    # unit_file_list.debug_print
    #-----------------------------------------------------------------------------
    # 出来上がった unit_file_list をファイル間の依存関係順に整列する.
    #-----------------------------------------------------------------------------
    unit_file_list.set_order_level
    unit_file_list.sort_by_level
    #-----------------------------------------------------------------------------
    # 
    #-----------------------------------------------------------------------------
    @library_info.each_key do |library_name|
      if library_name == :global
        lib_unit_file_list = unit_file_list.list
      else
        lib_unit_file_list = unit_file_list.list.select{|u| u.library_name == library_name}
      end
      #---------------------------------------------------------------------------
      # :execute が指定されている場合は シェルを通じて実行する.
      #---------------------------------------------------------------------------
      if @library_info[library_name][:execute]
        lib_unit_file_list.each do |unit_file|
          command = unit_file.to_formatted_string(@library_info[library_name][:execute])
          puts command
          system(command)
        end
      end
      #---------------------------------------------------------------------------
      # :print が指定されている場合は :format に従ってSTDOUTに出力.
      #---------------------------------------------------------------------------
      if @library_info[library_name][:print]
        lib_unit_file_list.each do |unit_file|
          puts unit_file.to_formatted_string(@library_info[library_name][:format])
        end
      end
      #---------------------------------------------------------------------------
      # :output_file_name が指定されている場合は :format に従ってファイルに出力.
      #---------------------------------------------------------------------------
      if @library_info[library_name][:output_file_name]
        File.open(@library_info[library_name][:output_file_name], "w") do |file|
          lib_unit_file_list.each do |unit_file|
            file.puts unit_file.to_formatted_string(@library_info[library_name][:format])
          end
        end
      end
      #---------------------------------------------------------------------------
      # :archive_file_name が指定されている場合は 指定された順番でひとつのファイル
      # にまとめる.
      #---------------------------------------------------------------------------
      if @library_info[library_name][:archive_file_name]
        File.open(@library_info[library_name][:archive_file_name], "w") do |file|
          lib_unit_file_list.each do |unit_file|
            file.write File.open(unit_file.file_name, "r").read
          end
        end
      end
    end
  end
end

archiver = VhdlArchiver.new
archiver.parse_options(ARGV)
archiver.execute
