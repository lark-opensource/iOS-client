// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_module.h"

#include <string>

#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

static const char* extern_type_kinds[] = {"function", "global", "table",
                                          "memory"};

WasmModule::WasmModule(wasm_module_t* module, WasmRuntime* wasm_rt)
    : module_(module), wasm_rt_(wasm_rt) {
  WasmRuntime::Dup(wasm_rt_);
}

WasmModule::~WasmModule() {
  if (module_) wasm_module_delete(module_);
  WasmRuntime::Free(wasm_rt_);
}

void WasmModule::exports(js_context ctx, js_value array, js_value* exception) {
  wasm_exporttype_vec_t export_types;
  wasm_module_exports(module_, &export_types);

  JS_ENV* js_env = wasm_rt_->GetJSEnv();
  for (size_t i = 0; i < export_types.size; ++i) {
    const wasm_externtype_t* e_type =
        wasm_exporttype_type(export_types.data[i]);
    const char* kind_str = extern_type_kinds[wasm_externtype_kind(e_type)];
    js_value temp = js_env->MakePlainObject();
    js_value js_kind_str = js_env->MakeString(kind_str);
    // Here we create js string of "kind" & "name" every time.
    // TODO(wasm):
    // If this method is frequently called, find a way
    // to save this overhead while being compitable
    // to different js engines.
    js_env->SetProperty(temp, "kind", js_kind_str);

    const wasm_name_t* e_name = wasm_exporttype_name(export_types.data[i]);
    std::string e_name_str(e_name->data, e_name->size);
    js_value name_str = js_env->MakeString(e_name_str.c_str());
    js_env->SetProperty(temp, "name", name_str);

    js_env->SetPropertyAtIndex(array, i, temp);
  }
}

void WasmModule::imports(js_context ctx, js_value array, js_value* exception) {
  wasm_importtype_vec_t import_types;
  wasm_module_imports(module_, &import_types);

  JS_ENV* js_env = wasm_rt_->GetJSEnv();
  for (size_t i = 0; i < import_types.size; ++i) {
    const wasm_externtype_t* e_type =
        wasm_importtype_type(import_types.data[i]);
    const char* kind_str = extern_type_kinds[wasm_externtype_kind(e_type)];
    js_value temp = js_env->MakePlainObject();
    js_value js_kind_str = js_env->MakeString(kind_str);
    js_env->SetProperty(temp, "kind", js_kind_str);

    const wasm_name_t* e_name = wasm_importtype_module(import_types.data[i]);
    std::string module_str(e_name->data, e_name->size);
    js_value js_module_str = js_env->MakeString(module_str.c_str());
    js_env->SetProperty(temp, "module", js_module_str);

    e_name = wasm_importtype_name(import_types.data[i]);
    std::string name_str(e_name->data, e_name->size);
    js_value js_name_str = js_env->MakeString(name_str.c_str());
    js_env->SetProperty(temp, "name", js_name_str);

    js_env->SetPropertyAtIndex(array, i, temp);
  }
}

}  // namespace wasm
}  // namespace vmsdk