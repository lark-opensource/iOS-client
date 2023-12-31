##### LynxV8Bridge
cmake_minimum_required(VERSION 3.4.1)

set(JS_V8_BRIDGE
        ../../base/log/log_stream.cc
        ../../base/observer/observer_list.cc
        v8_cache_generator.cc
        v8_context_wrapper_impl.cc
        v8_exception.cc
        v8_helper.cc
        v8_host_function.cc
        v8_host_object.cc
        v8_isolate_wrapper_impl.cc
        v8_runtime.cc)

if (ENABLE_NAPI_BINDING)
    set(NAPI_V8_BRIDGE_HEADERS
            ../../../third_party/napi/include
            )
    set(NAPI_V8_LIBRARYS
            ${CMAKE_CURRENT_SOURCE_DIR}/../../../Android/LynxAndroid/build/jniLibs/vmsdk/jni/${ANDROID_ABI}/libnapi.so
            ${CMAKE_CURRENT_SOURCE_DIR}/../../../Android/LynxAndroid/build/jniLibs/vmsdk/jni/${ANDROID_ABI}/libnapi_v8.so
            )
endif()

if (ENABLE_NAPI_BINDING)
    set(NAPI_V8_BINDING ../napi/napi_runtime_proxy_v8.cc)
endif ()

include_directories(
        ${JS_V8_HEADERS}
        ${NAPI_V8_BRIDGE_HEADERS}
)

add_library(lynx_v8_bridge SHARED
        ../android/jni_v8_bridge.cc
        ${JS_V8_BRIDGE}
        ${HELIUM_V8_BRIDGE_FILES}
        ${NAPI_V8_BINDING}
        )
set_target_properties(lynx_v8_bridge PROPERTIES LINKER_LANGUAGE CXX)
target_compile_options(lynx_v8_bridge PUBLIC -Oz)
target_link_libraries(lynx_v8_bridge
        lynx
        ${JS_V8_LIBRARY}
        ${NAPI_V8_LIBRARYS}
        )
