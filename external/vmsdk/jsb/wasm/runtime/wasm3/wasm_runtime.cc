// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_runtime.h"

#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "math.h"
#include "wasm3/m3_api_libc.h"
#include "wasm3/wasm3.h"
#include "wasm_func_pack.h"
#include "wasm_global.h"
#include "wasm_instance.h"
#include "wasm_memory.h"
#include "wasm_module.h"
#include "wasm_table.h"

#ifdef ENABLE_MONITOR
#include "monitor/common/vmsdk_monitor.h"
#endif

namespace vmsdk {
namespace wasm {

#define WASM_STACK_SIZE 8192

WasmRuntime::WasmRuntime(JS_ENV* env)
    : js_env_(env), w3_env_(nullptr), w3_rt_(nullptr), ref_count_(1) {
  WLOGD("Loading WebAssembly...\n");

  js_env_->SetWasmRuntime(this);
}

WasmRuntime::~WasmRuntime() {
  WLOGD("%s: deleting WasmRuntime...\n", __func__);
  if (js_env_) delete js_env_;
  if (w3_rt_) m3_FreeRuntime(w3_rt_);
  if (w3_env_) m3_FreeEnvironment(w3_env_);
}

WasmModule* WasmRuntime::CreateWasmModule(void* data, size_t len) {
  if (w3_env_ == nullptr && InitRuntime()) {
    return nullptr;
  }
  M3Result result = m3Err_none;
  IM3Module module;
  // TODO(wasm):
  // For safety, it's better to copy this raw data in case of it is
  // released by JavaScript Runtime while the wasm runtime still need
  // this raw data.
  // If an instantiation process follows this module creation immediately,
  // this is not a big deal because we do Compilation in instantiation
  // after which the raw data is no longer needed.
  result =
      m3_ParseModule(w3_env_, &module, static_cast<const uint8_t*>(data), len);
  if (result) {
    WLOGI("m3_ParseModule: %s", result);
    return nullptr;
  }
  return new WasmModule(module);
}

// Note:
// There is no need to check whether wasm runtime is instantiated
// when creating a wasm instance, because only if a valid wasm
// module is provided this function will be called.
// TODO(wasm): Handle all kinds of imports.
std::shared_ptr<WasmInstance> WasmRuntime::CreateWasmInstance(
    WasmModule* mod, js_value imports_obj) {
  IM3Module w3_mod = mod->impl();
  if (!w3_mod) {
    WLOGI("create instance with invalid IM3Module!\n");
    return nullptr;
  }
  M3Result result = m3Err_none;

  std::shared_ptr<WasmInstance> res = std::make_shared<WasmInstance>(this);
  if (w3_mod->memoryImportInfo && LinkMemory(w3_mod, imports_obj, res.get())) {
    return nullptr;
  }

  if (w3_mod->tableImportInfo && LinkTable(w3_mod, imports_obj, res.get())) {
    return nullptr;
  }

  int gbl_nums = w3_mod->numGlobals;
  for (int i = 0; i < gbl_nums; i++) {
    M3Global gbl = w3_mod->globals[i];
    if (gbl.imported && LinkGlobal(w3_mod, imports_obj, res, i)) {
      return nullptr;
    }
  }

  result = m3_LoadModule(w3_rt_, w3_mod);
  if (result) {
    mod->invalidate();
    WLOGI("m3_LoadModule: %s\n", result);
    return nullptr;
  }
  // WasmModule no longer own this M3Module after it is loaded.
  // WasmInstance will be responsible for releasing w3_mod.
  mod->expire();

  res->SetImpl(w3_mod);

  result = m3_LinkLibC(w3_mod);
  if (result) {
    WLOGI("m3_LinkLibC: %s\n", result);
    return nullptr;
  }

  if (BindImports(imports_obj, w3_mod, res.get())) {
    WLOGI("Binding imports failed.\n");
    return nullptr;
  }

  result = m3_CompileModule(w3_mod);
  if (result) {
    WLOGI("m3_CompileModule : %s\n", result);
    return nullptr;
  }

  if (w3_mod->startFunction >= 0) {
    result = m3_RunStart(w3_mod);
    if (result) {
      WLOGI("m3_RunStart: %s\n", result);
      return nullptr;
    }
  }

  return res;
}

WasmMemory* WasmRuntime::CreateWasmMemory(uint32_t initial, uint32_t maximum,
                                          bool shared) {
  if (wasm_unlikely(w3_env_ == nullptr)) {
    if (InitRuntime()) return nullptr;
  }
  WLOGD("create memory with { init: %u, max: %u, shared: %u }", initial,
        maximum, shared);
  WasmMemory* mem = new WasmMemory(w3_rt_, initial, maximum, shared);
  if (!mem->valid()) {
    delete mem;
    return nullptr;
  }
  return mem;
}

WasmGlobal* WasmRuntime::CreateWasmGlobal(uint8_t type, bool mutability,
                                          double number) {
  if (wasm_unlikely(w3_env_ == nullptr)) {
    if (InitRuntime()) return nullptr;
  }

  WasmGlobal* gbl = new WasmGlobal(this, mutability, number, type);
  return gbl;
}

WasmTable* WasmRuntime::CreateWasmTable(uint32_t initial, uint32_t maximum,
                                        TableElementType type) {
  // only support funcref yet.
  DCHECK(type == TableElementType::FuncRef);
  if (wasm_unlikely(w3_env_ == nullptr)) {
    if (InitRuntime()) return nullptr;
  }
  WLOGI("CreateWasmTable with initial:%u, maximum: %u, type:%d\n", initial,
        maximum, type);
  WasmTable* tbl = new WasmTable(this, initial, maximum, type);
  if (!tbl->valid()) {
    delete tbl;
    return nullptr;
  }
  return tbl;
}

#if JS_ENGINE_QJS == 1
#define JS_DUP(js_env, val) js_env->ReserveObject(val)
#define JS_FREE(js_env, val) js_env->ReleaseObject(val)
#elif JS_ENGINE_JSC == 1
#define JS_DUP(js_env, val) ((js_value)val)
#define JS_FREE(js_env, val)
#else
#error No JS Engine specified!
#endif  // JS_ENGINE_QJS

int WasmRuntime::FillExportsObject(js_value obj, WasmModule* mod,
                                   std::shared_ptr<WasmInstance>& inst) {
  WLOGD("running WasmRuntime::%s", __func__);
  // Handle Functions.
  IM3Module w_inst = inst->GetImpl();
  IM3Function f = NULL;
  M3ExportedFunction* cur = w_inst->exportedFuncs;
  if (cur) {
    while ((f = cur->func)) {
      js_value prop = JS_NULL;
      int start_index = f->import.fieldUtf8 ? 1 : 0;
      WasmFuncPack* pck = new WasmFuncPack(f, this, inst);
      prop = js_env_->MakeFunction(f->names[start_index], pck);
      if (js_env_->IsNull(prop)) {
        LOGE("WasmRuntime: MakeFunction " << f->names[start_index]
                                          << " failed!");
        delete pck;
        return 1;
      }
      for (int i = start_index; i < f->numNames; ++i) {
        WLOGD("export function %s", f->names[i]);
        if (wasm_unlikely(!js_env_->SetProperty(obj, f->names[i],
                                                JS_DUP(js_env_, prop)))) {
          LOGE("WasmRuntime: SetProperty for exported function " << f->names[i]
                                                                 << " failed");
          JS_FREE(js_env_, prop);
          return 1;
        }
      }
      JS_FREE(js_env_, prop);
      while ((cur != nullptr) && (f == cur->func)) {
        cur = cur->next;
      }
    }
  }

  // Export Memory.
  if (w_inst->memoryName) {
    // NOTE:
    // If a memory is imported and then re-exported, no new
    // instance needs to be created again.
    js_value mem_obj = inst->GetMemoryObject();
    if (js_env_->IsNull(mem_obj)) {
      WasmMemory* memory = new WasmMemory(w_inst->memory, w3_rt_, inst);
      mem_obj = js_env_->MakeMemory(memory, memory->pages());
      if (js_env_->IsNull(mem_obj)) {
        delete memory;
        return 1;
      }
    } else {
      JS_DUP(js_env_, mem_obj);
    }
    if (wasm_unlikely(
            !js_env_->SetProperty(obj, w_inst->memoryName, mem_obj))) {
      LOGE("WasmRuntime: SetProperty for exported memory " << w_inst->memoryName
                                                           << "failed");
      return 1;
    }
  }

  // Export Table
  // if table0 exported, make WasmTable for exports.
  if (w_inst->tableInfo.tableName) {
    js_value js_tbl = inst->GetTableObject();
    if (js_env_->IsNull(js_tbl)) {
      IM3Table exported_tbl = m3_GetTable(w_inst);
      if (wasm_unlikely(exported_tbl == NULL)) {
        return 1;
      }
      WasmTable* tbl = new WasmTable(this, exported_tbl, inst);
      js_tbl = js_env_->MakeTable(tbl);
      if (wasm_unlikely(js_env_->IsNull(js_tbl))) {
        delete tbl;
        return 1;
      }
    } else {
      JS_DUP(js_env_, js_tbl);
    }
    if (wasm_unlikely(
            !js_env_->SetProperty(obj, w_inst->tableInfo.tableName, js_tbl))) {
      LOGE("WasmRuntime: SetProperty for exported table "
           << w_inst->tableInfo.tableName << " failed");
      return 1;
    }
  }

  for (int i = 0; i < w_inst->numGlobals; i++) {
    M3Global gbl_obj = w_inst->globals[i];
    if (gbl_obj.name) {
      js_value js_gbl = inst->GetGlobalObject(i);
      if (js_env_->IsNull(js_gbl)) {
        WasmGlobal* gbl = new WasmGlobal(this, w_inst->globals + i, inst);
        js_gbl = js_env_->MakeGlobal(gbl);
        if (wasm_unlikely(js_env_->IsNull(js_gbl))) {
          delete gbl;
          return 1;
        }
      } else {
        JS_DUP(js_env_, js_gbl);
      }
      if (wasm_unlikely(!js_env_->SetProperty(obj, gbl_obj.name, js_gbl))) {
        LOGE("WasmRuntime: SetProperty for exported global " << gbl_obj.name
                                                             << " failed");
        return 1;
      }
    }
  }

  return 0;
}

#undef JS_DUP
#undef JS_FREE

int WasmRuntime::JsToWasm(const js_value val, M3ValueType m3_type, u64* w_val) {
  // Only support number yet.
  if (!js_env_->IsNumber(val)) return 1;
  double dvalue = js_env_->ValueToNumber(val);

  switch (m3_type) {
    case c_m3Type_i32:
      if (wasm_unlikely(isnan(dvalue) || isinf(dvalue))) {
        *(reinterpret_cast<uint32_t*>(w_val)) = 0;
      } else {
        *(reinterpret_cast<uint32_t*>(w_val)) = static_cast<int32_t>(dvalue);
      }
      break;
    case c_m3Type_i64:
      if (wasm_unlikely(isnan(dvalue) || isinf(dvalue))) {
        *(reinterpret_cast<uint64_t*>(w_val)) = 0;
      } else {
        *(reinterpret_cast<uint64_t*>(w_val)) = static_cast<int64_t>(dvalue);
      }
      break;
    case c_m3Type_f32:
      *(reinterpret_cast<float*>(w_val)) = static_cast<float>(dvalue);
      break;
    case c_m3Type_f64:
      *(reinterpret_cast<double*>(w_val)) = dvalue;
      break;
    default:
      return 1;
  }
  return 0;
}

// FIXME(yangwenming):
// There is accuraccy loss in conversion from double to float,
// eg. 3.2 is transformed to 3.200000047683716.
// Find a way to avoid it.
int WasmRuntime::WasmToJs(js_value* val, M3ValueType m3_type, u64* w_val) {
  // Only support number yet.
  double dvalue = 0;
  switch (m3_type) {
    case c_m3Type_i32: {
      int32_t r = *(reinterpret_cast<int32_t*>(w_val));
      dvalue = static_cast<double>(r);
    } break;
    case c_m3Type_f32: {
      float r = *(reinterpret_cast<float*>(w_val));
      dvalue = static_cast<double>(r);
    } break;
    case c_m3Type_i64: {
      int64_t r = *(reinterpret_cast<int64_t*>(w_val));
      dvalue = static_cast<double>(r);
    } break;
    case c_m3Type_f64:
      dvalue = *(reinterpret_cast<double*>(w_val));
      break;
    default:
      return 1;
  }
  *val = js_env_->MakeNumber(dvalue);
  return 0;
}

void WasmRuntime::WasmFuncPackFinalizer(void* env) {
  WasmFuncPack* pack = static_cast<WasmFuncPack*>(env);
  delete pack;
}

int WasmRuntime::BindImports(const js_value import_val, IM3Module w3_mod,
                             WasmInstance* inst) {
  // Handle functions only.
  // FIXME: To support each type to be imported.
  bool is_empty = !js_env_->IsJSObject(import_val);

  for (u32 i = 0; i < w3_mod->numFunctions; ++i) {
    IM3Function target = Module_GetFunction(w3_mod, i);

    if (target->import.moduleUtf8 && target->import.fieldUtf8) {
      if (is_empty) {
        return 1;
      }
      const char* m_name = target->import.moduleUtf8;
      const char* f_name = target->import.fieldUtf8;
      js_value val = LookupImport(import_val, m_name, f_name);
      if (!js_env_->IsJSFunction(val)) return 1;

      WasmFuncPack* pack = new WasmFuncPack(val, this);
      std::string sig = CreateSignature(target);
      // FIXME: consider when to release this `WasmFuncPack`.
      M3Result result =
          m3_LinkRawFunctionEx(w3_mod, m_name, f_name, sig.c_str(),
                               WasmFuncPack::WasmCallback, pack);
      if (result) {
        delete pack;
        return 1;
      }
      inst->PushImport(val);
      inst->AddJSCallbackEnv(pack);
    }
  }
  return 0;
}

js_value WasmRuntime::LookupImport(const js_value import_obj,
                                   const char* module_name,
                                   const char* field_name) {
  js_value may_import_module = js_env_->GetProperty(import_obj, module_name);

  if (js_env_->IsJSObject(may_import_module)) {
    js_value import_module = js_env_->ValueToObject(may_import_module);
    return js_env_->GetProperty(import_module, field_name);
  }
  return js_env_->GetUndefined();
}

std::string WasmRuntime::CreateSignature(IM3Function target) {
  u32 argc = m3_GetArgCount(target);
  u32 retc = m3_GetRetCount(target);
  std::string res;
  for (u32 i = 0; i < retc; ++i)
    res.push_back(ConvertTypeIdToTypeChar(m3_GetRetType(target, i)));

  res.push_back('(');
  for (u32 i = 0; i < argc; ++i)
    res.push_back(ConvertTypeIdToTypeChar(m3_GetArgType(target, i)));

  res.push_back(')');

  return res;
}

char WasmRuntime::ConvertTypeIdToTypeChar(M3ValueType ty) {
  switch (ty) {
    case c_m3Type_none:
      return 'v';
    case c_m3Type_i32:
      return 'i';
    case c_m3Type_i64:
      return 'I';
    case c_m3Type_f32:
      return 'f';
    case c_m3Type_f64:
      return 'F';
    // This branch is actually unreachable.
    default:
      return 0;
  }
}

int WasmRuntime::LinkTable(IM3Module mod, js_value imports_obj,
                           WasmInstance* inst) {
  const char* m_name = mod->tableImportInfo->moduleUtf8;
  const char* f_name = mod->tableImportInfo->fieldUtf8;
  js_value val = LookupImport(imports_obj, m_name, f_name);
  WasmTable* table = js_env_->GetTable(val);
  if (table) {
    inst->SetTableObject(val);
    M3Result res = m3_LinkTable(mod, table->impl());
    return res != m3Err_none;
  }
  return 1;
}

int WasmRuntime::LinkMemory(IM3Module mod, js_value imports_obj,
                            WasmInstance* inst) {
  const char* m_name = mod->memoryImportInfo->moduleUtf8;
  const char* f_name = mod->memoryImportInfo->fieldUtf8;
  js_value val = LookupImport(imports_obj, m_name, f_name);
  WasmMemory* memory = js_env_->GetMemory(val);
  if (memory) {
    inst->SetMemoryObject(val);
    M3Result res = m3_LinkMemory(mod, memory->impl());
    return res != m3Err_none;
  }
  return 1;
}

int WasmRuntime::LinkGlobal(IM3Module mod, js_value imports_obj,
                            std::shared_ptr<WasmInstance>& inst, int idx) {
  const char* m_name = mod->globals[idx].import.moduleUtf8;
  const char* f_name = mod->globals[idx].import.fieldUtf8;

  IM3Global this_gbl = mod->globals + idx;
  js_value val = LookupImport(imports_obj, m_name, f_name);

  WasmGlobal* global = nullptr;
  js_value value = js_env_->GetUndefined();

  if (js_env_->IsNumber(val)) {
    value = val;

    global = new WasmGlobal(this, this_gbl, inst);
    val = js_env_->MakeGlobal(global);
  } else {
    global = js_env_->GetGlobal(val);
    if (!global) {
      return 1;
    }
    global->get_value(&value);
  }

  if (global) {
    // Only get a number from imported Global.
    // Because JSC cannot figure out wether val is BigInt or Int64 or float32 or
    // Int32, it can only read Number, so we do not making a convert here.
    double number = js_env_->ValueToNumber(value);

    inst->SetGlobalObject(val, idx);
    global->ImportGlobal(this_gbl);
    global->SetInstance(inst);
    return global->SetLinkedValue(number);
  }
  return 1;
}

int WasmRuntime::InitRuntime() {
#ifdef ENABLE_MONITOR
  MonitorEvent(MODULE_VMSDK_WASM, DEFAULT_BIZ_NAME, "Wasm3Runtime", "true");
#endif
  w3_env_ = m3_NewEnvironment();
  if (!w3_env_) {
    WLOGI("m3_NewEnvironment failed");
    return 1;
  }
  w3_rt_ = m3_NewRuntime(w3_env_, WASM_STACK_SIZE, NULL);
  if (!w3_rt_) {
    WLOGI("m3_NewRuntime failed");
    return 1;
  }
  w3_rt_->memoryLimit = 0;
  return 0;
}

void WasmRuntime::Free(WasmRuntime* runtime) {
  if (--(runtime->ref_count_) < 1) {
    delete runtime;
  }
}

void WasmRuntime::Dup(WasmRuntime* runtime) { ++runtime->ref_count_; }

}  // namespace wasm
}  // namespace vmsdk
