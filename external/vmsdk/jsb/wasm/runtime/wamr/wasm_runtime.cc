// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_runtime.h"

#include <string>

#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "wasm_func_pack.h"
#include "wasm_instance.h"
#include "wasm_module.h"

#ifdef ENABLE_MONITOR
#include "monitor/common/vmsdk_monitor.h"
#endif

namespace vmsdk {
namespace wasm {

WasmRuntime::WasmRuntime(JS_ENV* env)
    : js_env_(env), wasm_engine_(nullptr), wasm_store_(nullptr), ref_count_(1) {
  js_env_->SetWasmRuntime(this);
}

WasmRuntime::~WasmRuntime() {
  WLOGD("deleting-wasm-runtime...");
  if (js_env_) delete js_env_;
  if (wasm_store_) {
    wasm_store_delete(wasm_store_);
  }
  if (wasm_engine_) {
    wasm_engine_delete(wasm_engine_);
  }
}

WasmTable* WasmRuntime::CreateWasmTable(uint32_t initial, uint32_t maximum,
                                        TableElementType type) {
  // only support funcref yet.
  DCHECK(type == TableElementType::FuncRef);
  WLOGI("CreateWasmTable with initial:%u, maximum: %u, type:%d\n", initial,
        maximum, type);
  return new WasmTable(this, NULL);
}

WasmMemory* WasmRuntime::CreateWasmMemory(uint32_t initial, uint32_t maximum,
                                          bool shared) {
  if (wasm_unlikely(wasm_store_ == nullptr)) {
    if (InitRuntime()) {
      return nullptr;
    }
  }
  return new WasmMemory(initial, maximum, shared);
}

WasmGlobal* WasmRuntime::CreateWasmGlobal(uint8_t type, bool mutability,
                                          double value) {
  wasm_val_t val = WASM_INIT_VAL;
  val.kind = WasmType(type);
  NumberToWasm(value, &val);
  return new WasmGlobal(NULL, mutability, &val, this);
}

WasmModule* WasmRuntime::CreateWasmModule(void* data, size_t len) {
  if (wasm_store_ == nullptr && InitRuntime()) {
    return nullptr;
  }
  wasm_byte_vec_t binary;
  binary.size = len;
  binary.data = static_cast<char*>(data);
  binary.num_elems = 0;
  binary.size_of_elem = 1;  // default one byte

  wasm_module_t* mod = wasm_module_new(wasm_store_, &binary);
  if (mod == nullptr) {
    return nullptr;
  }
  return new WasmModule(mod, this);
}

// Note:
// There is no need to check whether wasm runtime is instantiated
// when creating a wasm instance, because only if a valid wasm
// module is provided this function will be called.
std::shared_ptr<WasmInstance> WasmRuntime::CreateWasmInstance(
    WasmModule* mod, js_value imports_obj) {
  wasm_importtype_vec_t import_types;
  wasm_module_t* w_mod = mod->impl();
  wasm_module_imports(w_mod, &import_types);

  wasm_extern_t* externs[import_types.size];
  wasm_extern_vec_t imports_vec = WASM_ARRAY_VEC(externs);
  // When the module requires non-empty importing object, aka import_types.size
  // > 0, we return nullptr if no imported object is provided or import-binding
  // fails.
  std::shared_ptr<WasmInstance> inst = std::make_shared<WasmInstance>(this);
  if (import_types.size &&
      BindImports(imports_obj, &import_types, externs, inst.get())) {
    return nullptr;
  }

  wasm_instance_t* inst_impl = wasm_instance_new_with_args(
      wasm_store_, w_mod, &imports_vec, NULL, KILOBYTE(32), 0);
  if (!inst_impl) {
    return nullptr;
  }
  inst->SetImpl(inst_impl);
  return inst;
}

void WasmRuntime::WasmToJs(js_value* val, wasm_val_t* w_val) {
  switch (w_val->kind) {
    case WASM_I32:
      *val = js_env_->MakeNumber(w_val->of.i32);
      break;
    case WASM_I64:
      *val = js_env_->MakeNumber(w_val->of.i64);
      break;
    case WASM_F32:
      *val = js_env_->MakeNumber(w_val->of.f32);
      break;
    case WASM_F64:
      *val = js_env_->MakeNumber(w_val->of.f64);
      break;
    case WASM_ANYREF:
    case WASM_FUNCREF:
      // FIXME(wasm): handle reference correctly.
      // *val = reinterpret_cast<js_value>(w_val->of.ref);
      break;
  }
}

int WasmRuntime::NumberToWasm(double dvalue, wasm_val_t* w_val) {
  switch (w_val->kind) {
    case WASM_I32:
      if (wasm_unlikely(isnan(dvalue) || isinf(dvalue))) {
        w_val->of.i32 = 0;
      } else {
        w_val->of.i32 = static_cast<int32_t>(dvalue);
      }
      break;
    case WASM_I64:
      if (wasm_unlikely(isnan(dvalue) || isinf(dvalue))) {
        w_val->of.i64 = 0;
      } else {
        w_val->of.i64 = static_cast<int64_t>(dvalue);
      }
      break;
    case WASM_F32:
      w_val->of.f32 = static_cast<float>(dvalue);
      break;
    case WASM_F64:
      w_val->of.f64 = dvalue;
      break;
    // TODO: Cover there two cases.
    case WASM_FUNCREF:
    case WASM_ANYREF:
      assert(false && "Unimplemented!");
      break;
  }
  return 0;
}

int WasmRuntime::JsToWasm(const js_value val, wasm_val_t* w_val) {
  if (!js_env_->IsNumber(val)) return 1;
  double dvalue = js_env_->ValueToNumber(val);
  return NumberToWasm(dvalue, w_val);
}

int WasmRuntime::BindImports(const js_value import_val,
                             wasm_importtype_vec_t* iv, wasm_extern_t** imports,
                             WasmInstance* inst) {
  if (!js_env_->IsJSObject(import_val)) return 1;
  // do not consider importing tables & memories here
  js_value import_obj = js_env_->ValueToObject(import_val);
  for (size_t i = 0; i < iv->size; ++i) {
    // TODO(wasm): consider to introduce a fast way to bind imports
    //  without comparing their names, based on a hypothosis that imports
    //  are assigned in a right order.
    js_value bind_target = LookupImport(import_obj, iv->data[i]);
    if (js_env_->IsUndefined(bind_target)) {
      return 1;
    }
    inst->PushImport(bind_target);
    const wasm_externtype_t* ity = wasm_importtype_type(iv->data[i]);
    const wasm_externkind_t e_kind = wasm_externtype_kind(ity);
    switch (e_kind) {
      case WASM_EXTERN_GLOBAL: {
        WasmGlobal* global =
            reinterpret_cast<WasmGlobal*>(js_env_->GetGlobal(bind_target));
        wasm_global_t* gbl = wasm_global_new(
            wasm_store_, wasm_externtype_as_globaltype_const(ity),
            global->value());
        global->set_global(gbl);
        imports[i] = wasm_global_as_extern(gbl);
        break;
      }
      case WASM_EXTERN_MEMORY:
        assert(false && "importing a memory is not supported.");
        break;
      case WASM_EXTERN_TABLE:
        assert(false && "importing a table is not supported.");
        break;
      case WASM_EXTERN_FUNC: {
        js_value func_obj = js_env_->ValueToFunction(bind_target);
        if (!js_env_->IsNull(func_obj)) {
          const wasm_functype_t* fty = wasm_externtype_as_functype_const(ity);
          WasmFuncPack* pack = new WasmFuncPack(func_obj, this);
          wasm_func_t* wfunc = wasm_func_new_with_env(
              wasm_store_, fty, WasmFuncPack::WasmCallback, pack,
              WasmFuncPackFinalizer);
          imports[i] = wasm_func_as_extern(wfunc);
          break;
        }
        return 1;
      }
    }
  }
  return 0;
}

js_value WasmRuntime::LookupImport(const js_value import_obj,
                                   wasm_importtype_t* ity) {
  const wasm_name_t* m_name = NULL;
  m_name = wasm_importtype_module(ity);

  std::string c_name(m_name->data, m_name->size);
  js_value may_import_module = js_env_->GetProperty(import_obj, c_name.c_str());

  if (js_env_->IsJSObject(may_import_module)) {
    js_value import_module = js_env_->ValueToObject(may_import_module);
    m_name = wasm_importtype_name(ity);
    c_name = std::string(m_name->data, m_name->size);
    return js_env_->GetProperty(import_module, c_name.c_str());
  }
  return js_env_->GetUndefined();
}

int WasmRuntime::FillExportsObject(js_value export_obj, WasmModule* w_mod,
                                   std::shared_ptr<WasmInstance>& w_inst) {
  wasm_module_t* mod = w_mod->impl();
  wasm_instance_t* inst = w_inst->GetImpl();
  wasm_extern_vec_t exports;

  wasm_instance_exports(inst, &exports);
  wasm_exporttype_vec_t export_types;
  wasm_module_exports(mod, &export_types);
  size_t export_size = exports.size;
  for (size_t i = 0; i < export_size; ++i) {
    const wasm_externtype_t* type = wasm_exporttype_type(export_types.data[i]);
    const wasm_name_t* ename = wasm_exporttype_name(export_types.data[i]);
    js_value prop = JS_NULL;
    assert(wasm_extern_kind(exports.data[i]) == wasm_externtype_kind(type));
    switch (wasm_externtype_kind(type)) {
      case WASM_EXTERN_FUNC: {
        wasm_func_t* func = wasm_extern_as_func(exports.data[i]);
        char buf[11];
        snprintf(buf, sizeof(buf), "%zu", i);
        WasmFuncPack* pck = new WasmFuncPack(func, this, w_inst);
        prop = js_env_->MakeFunction(buf, pck);
        if (js_env_->IsNull(prop)) {
          delete pck;
          return 1;
        }
      } break;
      case WASM_EXTERN_GLOBAL: {
        wasm_global_t* global = wasm_extern_as_global(exports.data[i]);
        wasm_val_t val;
        wasm_global_get(global, &val);
        bool mutability = WasmGlobal::mutability(global);
        WasmGlobal* gbl =
            new WasmGlobal(global, mutability, &val, this, w_inst);
        prop = js_env_->MakeGlobal(gbl);
        if (js_env_->IsNull(prop)) {
          delete gbl;
          return 1;
        }
      } break;
      case WASM_EXTERN_MEMORY: {
        wasm_memory_t* memory = wasm_extern_as_memory(exports.data[i]);
        WasmMemory* mem_wrapper = new WasmMemory(memory, w_inst);
        prop = js_env_->MakeMemory(mem_wrapper, mem_wrapper->pages());
        if (js_env_->IsNull(prop)) {
          delete mem_wrapper;
          return 1;
        }
      } break;
      case WASM_EXTERN_TABLE: {
        wasm_table_t* table = wasm_extern_as_table(exports.data[i]);
        WasmTable* tbl = new WasmTable(this, table, w_inst);
        prop = js_env_->MakeTable(tbl);
        if (js_env_->IsNull(prop)) {
          delete tbl;
          return 1;
        }
      } break;
      default:
        assert(false && "unreachable code.");
    }
    std::string prop_name_str(ename->data, ename->size);
    if (!js_env_->SetProperty(export_obj, prop_name_str.c_str(), prop)) {
#if JS_ENGINE_QJS == 1
      js_env_->ReleaseObject(prop);
#endif  // JS_ENGINE_QJS == 1
      return 1;
    }
  }
  return 0;
}

void WasmRuntime::WasmFuncPackFinalizer(void* env) {
  WasmFuncPack* pack = static_cast<WasmFuncPack*>(env);
  delete pack;
}

wasm_valkind_t WasmRuntime::WasmType(uint8_t type) {
  switch (type) {
    case WasmGlobal::kTypeI32:
      return WASM_I32;
    case WasmGlobal::kTypeI64:
      return WASM_I64;
    case WasmGlobal::kTypeF32:
      return WASM_F32;
    case WasmGlobal::kTypeF64:
      return WASM_F64;
    case WasmGlobal::kTypeExternref:
      return WASM_FUNCREF;
    default:
      return WASM_ANYREF;
  }
}

int WasmRuntime::InitRuntime() {
#ifdef ENABLE_MONITOR
  MonitorEvent(MODULE_VMSDK_WASM, DEFAULT_BIZ_NAME, "WamrRuntime", "true");
#endif
  wasm_engine_ = wasm_engine_new();
  wasm_store_ = wasm_store_new(wasm_engine_);
  return !wasm_engine_ || !wasm_store_;
}

void WasmRuntime::Free(WasmRuntime* runtime) {
  if (--(runtime->ref_count_) < 1) {
    delete runtime;
  }
}

void WasmRuntime::Dup(WasmRuntime* runtime) { ++runtime->ref_count_; }

}  // namespace wasm
}  // namespace vmsdk
