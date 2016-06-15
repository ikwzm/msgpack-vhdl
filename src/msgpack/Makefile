PIPEWORK_DIR = ../../../PipeWork
COPY         = cp
CAT          = cat
REMOVE       = -rm


PIPEWORK_COMP_FILE    = pipework/pipework_components.vhd

PIPEWORK_ENTITY_FILES = pipework/reducer.vhd               \
                        pipework/chopper.vhd               \
                        pipework/queue_register.vhd        \
                        pipework/queue_arbiter.vhd         \
                        $(END_LIST)

PIPEWORK_SOURCE_FILES = $(PIPEWORK_ENTITY_FILES)           \
                        $(PIPEWORK_COMP_FILE)              \
                        $(END_LIST)

OBJECT_COMP_FILE      = object/msgpack_object_components.vhd

OBJECT_PACKAGE_FILES  = object/msgpack_object.vhd                           \
                        $(END_LIST)

OBJECT_ENTITY_FILES   = object/msgpack_object_packer.vhd                    \
                        object/msgpack_object_unpacker.vhd                  \
                        object/msgpack_object_code_reducer.vhd              \
                        object/msgpack_object_code_fifo.vhd                 \
                        object/msgpack_object_code_compare.vhd              \
                        object/msgpack_object_decode_array.vhd              \
                        object/msgpack_object_decode_binary_core.vhd        \
                        object/msgpack_object_decode_binary_array.vhd       \
                        object/msgpack_object_decode_binary_stream.vhd      \
                        object/msgpack_object_decode_map.vhd                \
                        object/msgpack_object_decode_boolean.vhd            \
                        object/msgpack_object_decode_integer.vhd            \
                        object/msgpack_object_decode_integer_array.vhd      \
                        object/msgpack_object_decode_integer_stream.vhd     \
                        object/msgpack_object_encode_array.vhd              \
                        object/msgpack_object_encode_map.vhd                \
                        object/msgpack_object_encode_binary_array.vhd       \
                        object/msgpack_object_encode_binary_stream.vhd      \
                        object/msgpack_object_encode_boolean.vhd            \
                        object/msgpack_object_encode_integer.vhd            \
                        object/msgpack_object_encode_integer_array.vhd      \
                        object/msgpack_object_encode_integer_stream.vhd     \
                        object/msgpack_object_encode_string_constant.vhd    \
                        object/msgpack_structure_stack.vhd                  \
                        object/msgpack_object_match_aggregator.vhd          \
                        object/msgpack_object_store_array.vhd               \
                        object/msgpack_object_store_boolean_register.vhd    \
                        object/msgpack_object_store_integer_register.vhd    \
                        object/msgpack_object_store_integer_array.vhd       \
                        object/msgpack_object_store_integer_stream.vhd      \
                        object/msgpack_object_store_binary_array.vhd        \
                        object/msgpack_object_store_binary_stream.vhd       \
                        object/msgpack_object_query_stream_parameter.vhd    \
                        object/msgpack_object_query_boolean_register.vhd    \
                        object/msgpack_object_query_integer_register.vhd    \
                        object/msgpack_object_query_integer_array.vhd       \
                        object/msgpack_object_query_integer_stream.vhd      \
                        object/msgpack_object_query_binary_array.vhd        \
                        object/msgpack_object_query_binary_stream.vhd       \
                        object/msgpack_object_query_array.vhd               \
                        $(END_LIST)

OBJECT_SOURCE_FILES   = $(OBJECT_COMP_FILE)      \
                        $(OBJECT_PACKAGE_FILES)  \
                        $(OBJECT_ENTITY_FILES)   \
                        $(END_LIST)

KVMAP_COMP_FILE       = kvmap/msgpack_kvmap_components.vhd                  \
                        $(END_LIST)

KVMAP_PACKAGE_FILES   = $(END_LIST)

KVMAP_ENTITY_FILES    = kvmap/msgpack_kvmap_key_compare.vhd                 \
                        kvmap/msgpack_kvmap_key_match_aggregator.vhd        \
                        kvmap/msgpack_kvmap_dispatcher.vhd                  \
                        kvmap/msgpack_kvmap_store_boolean_register.vhd      \
                        kvmap/msgpack_kvmap_store_integer_register.vhd      \
                        kvmap/msgpack_kvmap_store_integer_array.vhd         \
                        kvmap/msgpack_kvmap_store_integer_stream.vhd        \
                        kvmap/msgpack_kvmap_store_binary_array.vhd          \
                        kvmap/msgpack_kvmap_store_binary_stream.vhd         \
                        kvmap/msgpack_kvmap_store_map_value.vhd             \
                        kvmap/msgpack_kvmap_store.vhd                       \
                        kvmap/msgpack_kvmap_query_boolean_register.vhd      \
                        kvmap/msgpack_kvmap_query_integer_register.vhd      \
                        kvmap/msgpack_kvmap_query_integer_array.vhd         \
                        kvmap/msgpack_kvmap_query_integer_stream.vhd        \
                        kvmap/msgpack_kvmap_query_binary_array.vhd          \
                        kvmap/msgpack_kvmap_query_binary_stream.vhd         \
                        kvmap/msgpack_kvmap_query_map_value.vhd             \
                        kvmap/msgpack_kvmap_query.vhd                       \
                        $(END_LIST)

KVMAP_SOURCE_FILES    = $(KVMAP_COMP_FILE)       \
                        $(KVMAP_PACKAGE_FILES)   \
                        $(KVMAP_ENTITY_FILES)    \
                        $(END_LIST)


RPC_COMP_FILE         = rpc/msgpack_rpc_components.vhd

RPC_PACKAGE_FILES     = rpc/msgpack_rpc.vhd                           \
                        $(END_LIST)

RPC_ENTITY_FILES      = rpc/msgpack_rpc_server.vhd                    \
                        rpc/msgpack_rpc_server_requester.vhd          \
                        rpc/msgpack_rpc_server_responder.vhd          \
                        rpc/msgpack_rpc_method_main_with_param.vhd    \
                        rpc/msgpack_rpc_method_main_no_param.vhd      \
                        rpc/msgpack_rpc_method_set_param_integer.vhd  \
                        rpc/msgpack_rpc_method_return_integer.vhd     \
                        rpc/msgpack_rpc_method_return_nil.vhd         \
                        rpc/msgpack_rpc_method_return_code.vhd        \
                        rpc/msgpack_rpc_server_kvmap_set_value.vhd    \
                        rpc/msgpack_rpc_server_kvmap_get_value.vhd    \
                        $(END_LIST)

RPC_SOURCE_FILES      = $(RPC_COMP_FILE)                              \
                        $(RPC_PACKAGE_FILES)                          \
                        $(RPC_ENTITY_FILES)                           \
                        $(END_LIST)


SOURCE_FILES          = $(PIPEWORK_SOURCE_FILES)                     \
                        $(OBJECT_SOURCE_FILES)                       \
                        $(KVMAP_SOURCE_FILES)                        \
                        $(RPC_SOURCE_FILES)                          \
                        $(END_LIST)


all: $(SOURCE_FILES)

clean:
	$(REMOVE) $(OBJECT_COMP_FILE) $(PIPEWORK_SOURCE_FILES)

$(OBJECT_COMP_FILE)   : $(OBJECT_ENTITY_FILES)
	$(PIPEWORK_DIR)/tools/MakeComponentPackage.rb --verbose \
            --brief   'MessagaPack Component Library Description' \
            --version 0.2.0 \
            --author  'Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>' \
            --library MsgPack \
            --package MsgPack_Object_Components \
            --output  $(OBJECT_COMP_FILE) \
            $(OBJECT_ENTITY_FILES)

$(RPC_COMP_FILE)      : $(RPC_ENTITY_FILES)
	$(PIPEWORK_DIR)/tools/MakeComponentPackage.rb --verbose \
            --brief   'MessagaPack Component Library Description' \
            --version 0.2.0 \
            --author  'Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>' \
            --library MsgPack \
            --package MsgPack_RPC_Components \
            --output  $(RPC_COMP_FILE) \
            $(RPC_ENTITY_FILES)

$(KVMAP_COMP_FILE)    : $(KVMAP_ENTITY_FILES)
	$(PIPEWORK_DIR)/tools/MakeComponentPackage.rb --verbose \
            --brief   'MessagaPack Component Library Description' \
            --version 0.2.0 \
            --author  'Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>' \
            --library MsgPack \
            --package MsgPack_KVMap_Components \
            --output  $(KVMAP_COMP_FILE) \
            $(KVMAP_ENTITY_FILES)


$(PIPEWORK_COMP_FILE) : $(PIPEWORK_ENTITY_FILES)
	$(PIPEWORK_DIR)/tools/MakeComponentPackage.rb --verbose \
            --brief   'MessagaPack Component Library Description' \
            --version 0.2.0 \
            --author  'Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>' \
            --library MsgPack \
            --package PipeWork_Components \
            --output  $(PIPEWORK_COMP_FILE) \
            $(PIPEWORK_ENTITY_FILES)

pipework/reducer.vhd            : $(PIPEWORK_DIR)/src/components/reducer.vhd
	$(COPY) $< $@

pipework/chopper.vhd            : $(PIPEWORK_DIR)/src/components/chopper.vhd
	$(COPY) $< $@

pipework/queue_register.vhd     : $(PIPEWORK_DIR)/src/components/queue_register.vhd
	$(COPY) $< $@

pipework/queue_arbiter.vhd      : $(PIPEWORK_DIR)/src/components/queue_arbiter.vhd $(PIPEWORK_DIR)/src/components/queue_arbiter_one_hot_arch.vhd
	$(CAT) $^ > $@
