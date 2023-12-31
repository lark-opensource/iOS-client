
#include "jsbridge/quickjs/quickjs_runtime.h"

#include <chrono>
#include <limits>
#include <utility>

#include "jsbridge/quickjs/quickjs_api.h"
#include "jsbridge/quickjs/quickjs_cache_generator.h"
#include "jsbridge/quickjs/quickjs_cache_maker_compatible.h"
#include "jsbridge/quickjs/quickjs_cache_manager.h"
#include "jsbridge/quickjs/quickjs_exception.h"
#include "jsbridge/quickjs/quickjs_host_function.h"
#include "jsbridge/quickjs/quickjs_host_object.h"
#include "jsbridge/runtime/runtime_constant.h"
#include "jsbridge/utils/args_converter.h"
#include "tasm/event_report_tracker.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace piper {

using detail::QuickjsHelper;
using detail::QuickjsHostFunctionProxy;
using detail::QuickjsHostObjectProxy;
using detail::QuickjsJSValueValue;

constexpr char kScriptUrlPrefix[] = "file://";

namespace {
void reportLepusToCStringError(Runtime &rt, const std::string &func_name,
                               int tag) {
  std::string error =
      func_name + " LepusToCString nullptr error! LepusValue's type tag is " +
      std::to_string(tag);
  LOGE(error);
  rt.reportJSIException(JSINativeException(error));
}
}  // namespace

QuickjsRuntime::QuickjsRuntime() : quickjs_runtime_wrapper_(nullptr){};

lynx::piper::QuickjsRuntime::~QuickjsRuntime() {
  *is_runtime_destroyed_ = true;
  Finalize();
  context_->Release();
  context_.reset();
  LOGI("LYNX free quickjs context");
}

void QuickjsRuntime::InitRuntime(std::shared_ptr<JSIContext> sharedContext,
                                 std::shared_ptr<JSIExceptionHandler> handler) {
  exception_handler_ = handler;
  quickjs_runtime_wrapper_ =
      std::static_pointer_cast<lynx::piper::QuickjsRuntimeInstance>(
          sharedContext->getVM());
  context_ = std::static_pointer_cast<QuickjsContextWrapper>(sharedContext);
}

std::shared_ptr<VMInstance> QuickjsRuntime::getSharedVM() {
  return quickjs_runtime_wrapper_;
}

std::shared_ptr<VMInstance> QuickjsRuntime::createVM(
    const StartupData *) const {
  return CreateVM_(nullptr, false);
}

std::shared_ptr<JSIContext> QuickjsRuntime::createContext(
    std::shared_ptr<VMInstance> vm) const {
  return CreateContext_(vm);
}

std::shared_ptr<JSIContext> QuickjsRuntime::getSharedContext() {
  return context_;
}

std::shared_ptr<QuickjsContextWrapper> QuickjsRuntime::CreateContext_(
    std::shared_ptr<VMInstance> vm) const {
  return std::make_shared<QuickjsContextWrapper>(vm);
}

std::shared_ptr<lynx::piper::QuickjsRuntimeInstance> QuickjsRuntime::CreateVM_(
    const char *arg, bool useSnapshot) const {
  auto quickjs_runtime_wrapper =
      std::make_shared<lynx::piper::QuickjsRuntimeInstance>();
  quickjs_runtime_wrapper->InitQuickjsRuntime();
  return quickjs_runtime_wrapper;
}

LEPUSClassID QuickjsRuntime::getFunctionClassID() const {
  return quickjs_runtime_wrapper_->getFunctionId();
};

LEPUSClassID QuickjsRuntime::getObjectClassID() const {
  return quickjs_runtime_wrapper_->getObjectId();
};

std::optional<Value> QuickjsRuntime::evaluateJavaScript(
    const std::shared_ptr<const Buffer> &buffer, const std::string &sourceURL) {
  auto start = std::chrono::high_resolution_clock::now();
  LOGI("execute script start: " << sourceURL);

  auto event = tasm::PropBundle::Create();
  event->set_tag("lynxsdk_code_cache");
  event->SetProps("source_url", sourceURL.c_str());
  event->SetProps("enable_user_code_cache", enable_user_code_cache_);
  std::shared_ptr<Buffer> cache;

  // enable code cache for kLynxCanvasJSName temporarily.
  // TODO(zhenziqi) Completely migrate to the new code cache
  if (enable_user_code_cache_ ||
      sourceURL.compare(runtime::kLynxCanvasJSName) == 0) {
#ifdef OS_ANDROID
    LOGI("using new code cache");
    auto &instance = cache::QuickjsCacheManager::GetInstance();
    auto generator =
        std::make_unique<cache::QuickjsCacheGenerator>(sourceURL, buffer);
    cache = instance.TryGetCache(sourceURL, code_cache_source_url_, buffer,
                                 std::move(generator));
#endif
  } else {
    QuickjsCacheMaker &instance = QuickjsCacheMaker::GetInstance();
    cache = instance.TryGetCache(sourceURL, code_cache_source_url_, buffer);
  }

  event->SetProps("cache_hit", (cache != nullptr));
  tasm::EventReportTracker::Report(std::move(event));
  std::optional<piper::Value> eval_res_opt;
  if (cache) {
    eval_res_opt = QuickjsHelper::evalBin(
        this, context_->getContext(),
        reinterpret_cast<const char *>(cache->data()), cache->size(),
        sourceURL.c_str(), LEPUS_EVAL_TYPE_GLOBAL);
  }
  if (!eval_res_opt) {
    LOGI("evaluateJavaScript evalBin fail! Now try to evalBuf.");
#ifdef OS_ANDROID
    if (enable_user_code_cache_ && cache) {
      cache::QuickjsCacheManager::GetInstance().RequestCacheGeneration(
          sourceURL, code_cache_source_url_, buffer,
          std::make_unique<cache::QuickjsCacheGenerator>(sourceURL, buffer),
          true);
    }
#endif
    // sourceURL must have a prefix when support js debugging.
    std::string view_id = "";
    if (debug_view_id_ > 0) {
      if (sourceURL.find("lynx_core") != std::string::npos) {
        view_id = "shared";
      } else {
        view_id = "view" + std::to_string(debug_view_id_);
      }
    }
    if (sourceURL.front() != '/') {
      view_id += '/';
    }

    eval_res_opt = QuickjsHelper::evalBuf(
        this, context_->getContext(),
        reinterpret_cast<const char *>(buffer->data()), buffer->size(),
        (kScriptUrlPrefix + view_id + sourceURL).c_str(),
        LEPUS_EVAL_TYPE_GLOBAL);
  }
  if (!eval_res_opt) {
    LOGI("evaluateJavaScript evalBuf fail!");
    return std::optional<Value>();
  }
  LOGI("evaluateJavaScript successfully!");
  auto finish = std::chrono::high_resolution_clock::now();
  UNUSED_LOG_VARIABLE double cost =
      std::chrono::duration_cast<std::chrono::nanoseconds>(finish - start)
          .count() /
      1000000.0;
  LOGI("evaluateJavaScript url=" << sourceURL << " cost=" << cost);

  return eval_res_opt;
}

std::shared_ptr<const PreparedJavaScript> QuickjsRuntime::prepareJavaScript(
    const std::shared_ptr<const Buffer> &buffer, std::string sourceURL) {
  return std::make_shared<piper::SourceJavaScriptPreparation>(
      buffer, std::move(sourceURL));
}

std::optional<Value> lynx::piper::QuickjsRuntime::evaluatePreparedJavaScript(
    const std::shared_ptr<const PreparedJavaScript> &js) {
  const SourceJavaScriptPreparation *source =
      static_cast<const SourceJavaScriptPreparation *>(js.get());
  return evaluateJavaScript(source->buffer(), source->sourceURL());
}

Object lynx::piper::QuickjsRuntime::global() {
  LEPUSValue global_obj = LEPUS_GetGlobalObject(context_->getContext());
  auto ret = QuickjsHelper::createJSValue(context_->getContext(), global_obj);
  return ret;
}

LEPUSValue QuickjsRuntime::valueRef(const piper::Value &value) {
  switch (value.kind()) {
    case Value::ValueKind::UndefinedKind:
      return LEPUS_UNDEFINED;
    case Value::ValueKind::NullKind:
      return LEPUS_NULL;
    case Value::ValueKind::BooleanKind:
      return LEPUS_NewBool(context_->getContext(), value.getBool());
    case Value::ValueKind::NumberKind:
      return LEPUS_NewFloat64(context_->getContext(), value.getNumber());
    case Value::ValueKind::SymbolKind:
      return QuickjsHelper::symbolRef(value.getSymbol(*this));
    case Value::ValueKind::StringKind:
      return QuickjsHelper::stringRef(value.getString(*this));
    case Value::ValueKind::ObjectKind:
      return QuickjsHelper::objectRef(value.getObject(*this));
  }
}

lynx::piper::Runtime::PointerValue *lynx::piper::QuickjsRuntime::cloneSymbol(
    const Runtime::PointerValue *pv) {
  if (!pv) {
    return nullptr;
  }
  const QuickjsJSValueValue *symbol =
      static_cast<const QuickjsJSValueValue *>(pv);
  return QuickjsHelper::makeJSValueValue(
      context_->getContext(),
      LEPUS_DupValue(context_->getContext(), symbol->Get()));
}

lynx::piper::Runtime::PointerValue *lynx::piper::QuickjsRuntime::cloneString(
    const Runtime::PointerValue *pv) {
  if (!pv) {
    return nullptr;
  }
  const QuickjsJSValueValue *string =
      static_cast<const QuickjsJSValueValue *>(pv);
  return QuickjsHelper::makeStringValue(
      context_->getContext(),
      LEPUS_DupValue(context_->getContext(), string->Get()));
}

lynx::piper::Runtime::PointerValue *lynx::piper::QuickjsRuntime::cloneObject(
    const Runtime::PointerValue *pv) {
  if (!pv) {
    return nullptr;
  }
  const QuickjsJSValueValue *object =
      static_cast<const QuickjsJSValueValue *>(pv);
  return QuickjsHelper::makeObjectValue(
      context_->getContext(),
      LEPUS_DupValue(context_->getContext(), object->Get()));
}

lynx::piper::Runtime::PointerValue *
lynx::piper::QuickjsRuntime::clonePropNameID(const Runtime::PointerValue *pv) {
  if (!pv) {
    return nullptr;
  }
  const QuickjsJSValueValue *string =
      static_cast<const QuickjsJSValueValue *>(pv);
  return QuickjsHelper::makeStringValue(
      context_->getContext(),
      LEPUS_DupValue(context_->getContext(), string->Get()));
}

lynx::piper::PropNameID lynx::piper::QuickjsRuntime::createPropNameIDFromAscii(
    const char *str, size_t length) {
  LEPUSValue value = LEPUS_NewStringLen(context_->getContext(), str, length);
  auto res = QuickjsHelper::createPropNameID(context_->getContext(), value);
  return res;
}

lynx::piper::PropNameID lynx::piper::QuickjsRuntime::createPropNameIDFromUtf8(
    const uint8_t *utf8, size_t length) {
  LEPUSValue value = LEPUS_NewStringLen(
      context_->getContext(), reinterpret_cast<const char *>(utf8), length);
  auto res = QuickjsHelper::createPropNameID(context_->getContext(), value);
  return res;
}

lynx::piper::PropNameID lynx::piper::QuickjsRuntime::createPropNameIDFromString(
    const lynx::piper::String &str) {
  return QuickjsHelper::createPropNameID(
      context_->getContext(),
      LEPUS_DupValue(context_->getContext(), QuickjsHelper::stringRef(str)));
}

std::string lynx::piper::QuickjsRuntime::utf8(
    const lynx::piper::PropNameID &sym) {
  return QuickjsHelper::LEPUSStringToSTLString(context_->getContext(),
                                               QuickjsHelper::valueRef(sym));
}

bool lynx::piper::QuickjsRuntime::compare(const lynx::piper::PropNameID &a,
                                          const lynx::piper::PropNameID &b) {
  std::string aa = QuickjsHelper::LEPUSStringToSTLString(
      context_->getContext(), QuickjsHelper::valueRef(a));
  std::string bb = QuickjsHelper::LEPUSStringToSTLString(
      context_->getContext(), QuickjsHelper::valueRef(b));
  return aa == bb;
}

std::optional<std::string> lynx::piper::QuickjsRuntime::symbolToString(
    const lynx::piper::Symbol &symbol) {
  auto str = piper::Value(*this, symbol).toString(*this);
  if (!str) {
    return std::optional<std::string>();
  }
  return str->utf8(*this);
}

lynx::piper::String lynx::piper::QuickjsRuntime::createStringFromAscii(
    const char *str, size_t length) {
  return this->createStringFromUtf8(reinterpret_cast<const uint8_t *>(str),
                                    length);
}

lynx::piper::String lynx::piper::QuickjsRuntime::createStringFromUtf8(
    const uint8_t *str, size_t length) {
  LEPUSValue value = LEPUS_NewStringLen(
      context_->getContext(), reinterpret_cast<const char *>(str), length);
  auto ret = QuickjsHelper::createString(context_->getContext(), value);
  return ret;
}

std::string lynx::piper::QuickjsRuntime::utf8(
    const lynx::piper::String &string) {
  return QuickjsHelper::LEPUSStringToSTLString(
      context_->getContext(), QuickjsHelper::stringRef(string));
}

lynx::piper::Object lynx::piper::QuickjsRuntime::createObject() {
  LEPUSValue value = LEPUS_NewObject(context_->getContext());
  //  LOGE( "LYNX" << "QuickjsRuntime::createObject() ptr=" <<
  //  LEPUS_VALUE_GET_PTR(value));
  return QuickjsHelper::createObject(context_->getContext(), value);
}

lynx::piper::Object lynx::piper::QuickjsRuntime::createObject(
    std::shared_ptr<HostObject> ho) {
  return QuickjsHostObjectProxy::createObject(this, ho);
}

std::shared_ptr<HostObject> lynx::piper::QuickjsRuntime::getHostObject(
    const piper::Object &object) {
  LEPUSValue obj = QuickjsHelper::objectRef(object);
  auto metadata = static_cast<detail::QuickjsHostObjectProxyBase *>(
      LEPUS_GetOpaque(obj, getObjectClassID()));
  DCHECK(metadata);
  return metadata->hostObject;
}

std::optional<Value> lynx::piper::QuickjsRuntime::getProperty(
    const lynx::piper::Object &object, const lynx::piper::PropNameID &name) {
  LEPUSValue v = QuickjsHelper::objectRef(object);
  const char *prop =
      LEPUS_ToCString(context_->getContext(), QuickjsHelper::valueRef(name));
  if (!prop) {
    int64_t tag = LEPUS_VALUE_GET_TAG(QuickjsHelper::valueRef(name));
    reportLepusToCStringError(*this, "QuickjsRuntime::getProperty", tag);
    return QuickjsHelper::createValue(LEPUS_UNDEFINED, this);
  }
  LEPUSValue result = LEPUS_GetPropertyStr(context_->getContext(), v, prop);
  LEPUS_FreeCString(context_->getContext(), prop);
  QuickjsException::ReportExceptionIfNeeded(*this, result);
  auto ret = QuickjsHelper::createValue(result, this);
  return ret;
}

std::optional<Value> lynx::piper::QuickjsRuntime::getProperty(
    const lynx::piper::Object &object, const lynx::piper::String &name) {
  LEPUSValue v = QuickjsHelper::objectRef(object);
  const char *prop =
      LEPUS_ToCString(context_->getContext(), QuickjsHelper::stringRef(name));
  if (!prop) {
    int64_t tag = LEPUS_VALUE_GET_TAG(QuickjsHelper::stringRef(name));
    reportLepusToCStringError(*this, "QuickjsRuntime::getProperty", tag);
    return QuickjsHelper::createValue(LEPUS_UNDEFINED, this);
  }
  LEPUSValue result = LEPUS_GetPropertyStr(context_->getContext(), v, prop);
  LEPUS_FreeCString(context_->getContext(), prop);
  QuickjsException::ReportExceptionIfNeeded(*this, result);
  auto ret = QuickjsHelper::createValue(result, this);
  return ret;
}

bool lynx::piper::QuickjsRuntime::hasProperty(
    const lynx::piper::Object &object, const lynx::piper::PropNameID &name) {
  LEPUSValue value = QuickjsHelper::objectRef(object);
  const char *n =
      LEPUS_ToCString(context_->getContext(), QuickjsHelper::valueRef(name));
  if (!n) {
    int64_t tag = LEPUS_VALUE_GET_TAG(QuickjsHelper::valueRef(name));
    reportLepusToCStringError(*this, "QuickjsRuntime::hasProperty", tag);
    return false;
  }
  LEPUSAtom atom = LEPUS_NewAtom(context_->getContext(), n);
  auto ret = LEPUS_HasProperty(context_->getContext(), value, atom);

  LEPUS_FreeCString(context_->getContext(), n);
  LEPUS_FreeAtom(context_->getContext(), atom);
  return ret;
}

bool lynx::piper::QuickjsRuntime::hasProperty(const lynx::piper::Object &object,
                                              const lynx::piper::String &name) {
  LEPUSValue value = QuickjsHelper::objectRef(object);
  const char *n =
      LEPUS_ToCString(context_->getContext(), QuickjsHelper::stringRef(name));
  if (!n) {
    int64_t tag = LEPUS_VALUE_GET_TAG(QuickjsHelper::stringRef(name));
    reportLepusToCStringError(*this, "QuickjsRuntime::hasProperty", tag);
    return false;
  }
  LEPUSAtom atom = LEPUS_NewAtom(context_->getContext(), n);
  auto ret = LEPUS_HasProperty(context_->getContext(), value, atom);

  LEPUS_FreeAtom(context_->getContext(), atom);
  LEPUS_FreeCString(context_->getContext(), n);
  return ret;
}

bool lynx::piper::QuickjsRuntime::setPropertyValue(
    lynx::piper::Object &object, const lynx::piper::PropNameID &name,
    const lynx::piper::Value &value) {
  LEPUSValue obj = QuickjsHelper::objectRef(object);
  LEPUSValue property = LEPUS_DupValue(context_->getContext(), valueRef(value));
  const char *property_str =
      LEPUS_ToCString(context_->getContext(), QuickjsHelper::valueRef(name));
  if (!property_str) {
    int64_t tag = LEPUS_VALUE_GET_TAG(QuickjsHelper::valueRef(name));
    reportLepusToCStringError(*this, "QuickjsRuntime::setPropertyValue", tag);
    return false;
  }
  int ret =
      LEPUS_SetPropertyStr(context_->getContext(), obj, property_str, property);
  LEPUS_FreeCString(context_->getContext(), property_str);
  if (ret == -1) {
    // TODO
    LOGE("setPropertyValue error");
  }
  return true;
}

bool lynx::piper::QuickjsRuntime::setPropertyValue(
    lynx::piper::Object &object, const lynx::piper::String &name,
    const lynx::piper::Value &value) {
  LEPUSValue obj = QuickjsHelper::objectRef(object);
  LEPUSValue property = LEPUS_DupValue(context_->getContext(), valueRef(value));
  //  LOGE( "LYNX setPropertyValue jsvalueptr=" <<
  //  LEPUS_VALUE_GET_PTR(property));
  const char *property_str =
      LEPUS_ToCString(context_->getContext(), QuickjsHelper::stringRef(name));
  if (!property_str) {
    int64_t tag = LEPUS_VALUE_GET_TAG(QuickjsHelper::stringRef(name));
    reportLepusToCStringError(*this, "QuickjsRuntime::setPropertyValue", tag);
    return false;
  }
  int ret =
      LEPUS_SetPropertyStr(context_->getContext(), obj, property_str, property);
  LEPUS_FreeCString(context_->getContext(), property_str);
  if (ret == -1) {
    // TODO
    LOGE("setPropertyValue error" << name.utf8(*this));
  }
  return true;
}

bool lynx::piper::QuickjsRuntime::isArray(
    const lynx::piper::Object &object) const {
  return LEPUS_IsArray(context_->getContext(),
                       QuickjsHelper::objectRef(object));
}

bool lynx::piper::QuickjsRuntime::isArrayBuffer(
    const lynx::piper::Object &object) const {
  return LEPUS_IsArrayBuffer(QuickjsHelper::objectRef(object));
}

bool lynx::piper::QuickjsRuntime::isFunction(
    const lynx::piper::Object &object) const {
  return LEPUS_IsFunction(context_->getContext(),
                          QuickjsHelper::objectRef(object));
}

bool lynx::piper::QuickjsRuntime::isHostObject(
    const piper::Object &object) const {
  LEPUSValue value = QuickjsHelper::objectRef(object);
  return LEPUS_GetOpaque(value, getObjectClassID()) != nullptr;
}

bool lynx::piper::QuickjsRuntime::isHostFunction(
    const piper::Function &function) const {
  LEPUSValue value = QuickjsHelper::objectRef(function);
  return LEPUS_GetOpaque(value, getFunctionClassID()) != nullptr;
}

std::optional<piper::Array> lynx::piper::QuickjsRuntime::getPropertyNames(
    const lynx::piper::Object &object) {
  LEPUSValue obj = QuickjsHelper::objectRef(object);
  LEPUSPropertyEnum *tab_exotic;
  uint32_t exotic_count = 0;
  LEPUSAtom atom;
  uint32_t i;
  LEPUS_GetOwnPropertyNames(
      context_->getContext(), &tab_exotic, &exotic_count, obj,
      LEPUS_GPN_STRING_MASK | LEPUS_GPN_SYMBOL_MASK | LEPUS_GPN_ENUM_ONLY);
  auto result = createArray(exotic_count);
  if (!result) {
    return std::optional<piper::Array>();
  }
  for (i = 0; i < exotic_count; i++) {
    atom = tab_exotic[i].atom;
    LEPUSValue name = LEPUS_AtomToValue(context_->getContext(), atom);
    if (!(*result).setValueAtIndex(
            *this, i,
            QuickjsHelper::createString(context_->getContext(), name))) {
      return std::optional<piper::Array>();
    }
  }
  uint32_t j;
  if (tab_exotic) {
    for (j = 0; j < exotic_count; j++)
      LEPUS_FreeAtom(context_->getContext(), tab_exotic[j].atom);
    lepus_free(context_->getContext(), tab_exotic);
  }
  return result;
}

std::optional<Array> lynx::piper::QuickjsRuntime::createArray(size_t length) {
  // https://tc39.es/ecma262/#sec-arraycreate
  if (length > std::numeric_limits<uint32_t>::max()) {
    // TODO(wangqingyu): Should throw a RangeError exception.
    return std::nullopt;
  }
  LEPUSValue arr = LEPUS_NewArray(context_->getContext());
  LEPUS_SetPropertyStr(
      context_->getContext(), arr, "length",
      LEPUS_NewFloat64(context_->getContext(), static_cast<double>(length)));
  return QuickjsHelper::createObject(context_->getContext(), arr)
      .getArray(*this);
}

// create BigInt object and and store value with key named "__lynx_val__", then
// add "toString" method to js object
std::optional<piper::BigInt> lynx::piper::QuickjsRuntime::createBigInt(
    const std::string &value, Runtime &rt) {
  LEPUSValue obj = LEPUS_NewObject(context_->getContext());

  // store value with key
  const std::string key = "__lynx_val__";
  LEPUSContext *context = context_->getContext();
  lynx::piper::String value_str =
      lynx::piper::String::createFromUtf8(rt, value);
  // 设置属性前必须调用LEPUS_DupValue方法将value复制，否则会crash
  LEPUS_DefinePropertyValueStr(context, obj, key.c_str(),
                               LEPUS_DupValue(context, valueRef(value_str)),
                               LEPUS_PROP_C_W_E);

  // create "toString" function
  const std::string to_str = "toString";
  const lynx::piper::PropNameID prop =
      lynx::piper::PropNameID::forUtf8(rt, to_str);
  const lynx::piper::Value fun_value =
      lynx::piper::Function::createFromHostFunction(
          rt, prop, 0,
          [value](Runtime &rt, const Value &thisVal, const Value *args,
                  unsigned int count) {
            lynx::piper::String res =
                lynx::piper::String::createFromUtf8(rt, value);

            return piper::Value(rt, res);
          });

  // add "toString" property to js object as a function
  LEPUS_DefinePropertyValueStr(context, obj, to_str.c_str(),
                               LEPUS_DupValue(context, valueRef(fun_value)),
                               LEPUS_PROP_C_W_E);

  // add "valueOf", "toJSON" property to js object as a function
  const std::string value_of = "valueOf";
  LEPUS_DefinePropertyValueStr(context, obj, value_of.c_str(),
                               LEPUS_DupValue(context, valueRef(fun_value)),
                               LEPUS_PROP_C_W_E);

  const std::string to_json = "toJSON";
  LEPUS_DefinePropertyValueStr(context, obj, to_json.c_str(),
                               LEPUS_DupValue(context, valueRef(fun_value)),
                               LEPUS_PROP_C_W_E);

  return QuickjsHelper::createObject(context_->getContext(), obj).getBigInt(rt);
}

lynx::piper::ArrayBuffer lynx::piper::QuickjsRuntime::createArrayBufferCopy(
    const uint8_t *bytes, size_t byte_length) {
  LEPUSValue array_buffer = LEPUS_UNDEFINED;
  if (bytes && byte_length > 0) {
    array_buffer =
        LEPUS_NewArrayBufferCopy(context_->getContext(), bytes, byte_length);
  }
  if (!QuickjsException::ReportExceptionIfNeeded(*this, array_buffer) ||
      LEPUS_VALUE_GET_TAG(array_buffer) == LEPUS_TAG_UNDEFINED ||
      LEPUS_VALUE_GET_TAG(array_buffer) == LEPUS_TAG_NULL) {
    return lynx::piper::ArrayBuffer(*this);
  }
  return QuickjsHelper::createObject(context_->getContext(), array_buffer)
      .getArrayBuffer(*this);
}

lynx::piper::ArrayBuffer lynx::piper::QuickjsRuntime::createArrayBufferNoCopy(
    std::unique_ptr<const uint8_t[]> bytes, size_t byte_length) {
  LEPUSFreeArrayBufferDataFunc *free_func = [](LEPUSRuntime *rt, void *opaque,
                                               void *ptr) {
    if (rt && ptr) {
      delete[] static_cast<uint8_t *>(ptr);
    }
  };
  LEPUSValue array_buffer = LEPUS_UNDEFINED;
  if (bytes && byte_length > 0) {
    const uint8_t *raw_buffer = bytes.release();
    array_buffer = LEPUS_NewArrayBuffer(context_->getContext(),
                                        const_cast<uint8_t *>(raw_buffer),
                                        byte_length, free_func, nullptr, false);
  }
  if (!QuickjsException::ReportExceptionIfNeeded(*this, array_buffer) ||
      LEPUS_VALUE_GET_TAG(array_buffer) == LEPUS_TAG_UNDEFINED ||
      LEPUS_VALUE_GET_TAG(array_buffer) == LEPUS_TAG_NULL) {
    return lynx::piper::ArrayBuffer(*this);
  }
  return QuickjsHelper::createObject(context_->getContext(), array_buffer)
      .getArrayBuffer(*this);
}

std::optional<size_t> lynx::piper::QuickjsRuntime::size(
    const lynx::piper::Array &array) {
  LEPUSValue arr = QuickjsHelper::objectRef(array);
  LEPUSValue jsLength =
      LEPUS_GetPropertyStr(context_->getContext(), arr, "length");
  size_t l = LEPUS_VALUE_GET_INT(jsLength);
  LEPUS_FreeValue(context_->getContext(), jsLength);
  return l;
}

size_t lynx::piper::QuickjsRuntime::size(
    const lynx::piper::ArrayBuffer &buffer) {
  size_t length = 0;
  LEPUS_GetArrayBuffer(context_->getContext(), &length,
                       QuickjsHelper::objectRef(buffer));
  return length;
}

uint8_t *lynx::piper::QuickjsRuntime::data(
    const lynx::piper::ArrayBuffer &array_buffer) {
  size_t length = 0;
  uint8_t *bytes = LEPUS_GetArrayBuffer(context_->getContext(), &length,
                                        QuickjsHelper::objectRef(array_buffer));
  return bytes;
}

size_t lynx::piper::QuickjsRuntime::copyData(const ArrayBuffer &array_buffer,
                                             uint8_t *dest_buf,
                                             size_t dest_len) {
  size_t src_len = array_buffer.length(*this);
  if (dest_len < src_len) {
    return 0;
  }
  size_t length = 0;
  uint8_t *bytes = LEPUS_GetArrayBuffer(context_->getContext(), &length,
                                        QuickjsHelper::objectRef(array_buffer));
  memcpy(dest_buf, bytes, length);
  return src_len;
}

std::optional<Value> lynx::piper::QuickjsRuntime::getValueAtIndex(
    const lynx::piper::Array &array, size_t i) {
  LEPUSValue arr = QuickjsHelper::objectRef(array);
  if (!LEPUS_IsArray(context_->getContext(), arr)) {
    LOGE("getValueAtIndex error. array is not an array");
    return piper::Value(nullptr);
  }
  LEPUSValue value = LEPUS_GetPropertyUint32(context_->getContext(), arr,
                                             static_cast<uint32_t>(i));
  //  LOGE( "LYNX getValueAtIndex jsvalueptr=" <<
  //  LEPUS_VALUE_GET_PTR(value));
  auto ret = QuickjsHelper::createValue(value, this);
  return ret;
}

bool lynx::piper::QuickjsRuntime::setValueAtIndexImpl(
    lynx::piper::Array &array, size_t i, const lynx::piper::Value &value) {
  LEPUSValue obj = QuickjsHelper::objectRef(array);
  //  LOGE( "LYNX setValueAtIndexImpl jsvalueptr=" <<
  //  LEPUS_VALUE_GET_PTR(obj));
  LEPUS_DefinePropertyValueUint32(
      context_->getContext(), obj, i,
      LEPUS_DupValue(context_->getContext(), valueRef(value)),
      LEPUS_PROP_C_W_E);
  return true;
}

lynx::piper::Function
lynx::piper::QuickjsRuntime::createFunctionFromHostFunction(
    const lynx::piper::PropNameID &name, unsigned int paramCount,
    HostFunctionType func) {
  LEPUSValue quick_func =
      QuickjsHostFunctionProxy::createFunctionFromHostFunction(
          this, context_->getContext(), name, paramCount, std::move(func));
  //  LOGE( "LYNX" << "createFunctionFromHostFunction ptr=" <<
  //  LEPUS_VALUE_GET_PTR(quick_func));
  return QuickjsHelper::createObject(context_->getContext(), quick_func)
      .getFunction(*this);
}

std::optional<Value> lynx::piper::QuickjsRuntime::call(
    const lynx::piper::Function &function, const lynx::piper::Value &jsThis,
    const lynx::piper::Value *args, size_t count) {
  auto converter = ArgsConverter<LEPUSValue>(
      count, args, [this](const auto &value) { return valueRef(value); });
  return QuickjsHelper::call(
      this, function,
      jsThis.isUndefined() ? QuickjsHelper::createObject(context_->getContext(),
                                                         LEPUS_UNINITIALIZED)
                           : jsThis.getObject(*this),
      converter, count);
}

std::optional<Value> lynx::piper::QuickjsRuntime::callAsConstructor(
    const lynx::piper::Function &function, const lynx::piper::Value *args,
    size_t count) {
  auto converter = ArgsConverter<LEPUSValue>(
      count, args, [this](const auto &value) { return valueRef(value); });
  return QuickjsHelper::callAsConstructor(
      this, QuickjsHelper::objectRef(function), converter, count);
}

lynx::piper::Runtime::ScopeState *lynx::piper::QuickjsRuntime::pushScope() {
  return Runtime::pushScope();
}

void lynx::piper::QuickjsRuntime::popScope(
    lynx::piper::Runtime::ScopeState *state) {
  Runtime::popScope(state);
}

bool lynx::piper::QuickjsRuntime::strictEquals(
    const lynx::piper::Symbol &a, const lynx::piper::Symbol &b) const {
  return LEPUS_VALUE_GET_PTR(QuickjsHelper::symbolRef(a)) ==
         LEPUS_VALUE_GET_PTR(QuickjsHelper::symbolRef(b));
}

bool lynx::piper::QuickjsRuntime::strictEquals(
    const lynx::piper::String &a, const lynx::piper::String &b) const {
  // LEPUS_StrictEq does the following for comparing two strings:
  //   1. Check if ptr are equals
  //     1.1 Return true if equals
  //   2. Check if they are atoms
  //     2.1 Return false if both are atoms
  //   3. Do the real string compare
  //   4. Free two strings
  // Thus, we should DupValue before calling LEPUS_StrictEq
  LEPUSContext *context = context_->getContext();
  return LEPUS_StrictEq(context,
                        LEPUS_DupValue(context, QuickjsHelper::stringRef(a)),
                        LEPUS_DupValue(context, QuickjsHelper::stringRef(b)));
}

bool lynx::piper::QuickjsRuntime::strictEquals(
    const lynx::piper::Object &a, const lynx::piper::Object &b) const {
  return LEPUS_VALUE_GET_PTR(QuickjsHelper::objectRef(a)) ==
         LEPUS_VALUE_GET_PTR(QuickjsHelper::objectRef(b));
}

bool lynx::piper::QuickjsRuntime::instanceOf(const lynx::piper::Object &o,
                                             const lynx::piper::Function &f) {
  int ret =
      LEPUS_IsInstanceOf(context_->getContext(), QuickjsHelper::objectRef(o),
                         QuickjsHelper::objectRef(f));
  return ret == 1;
}

void QuickjsRuntime::AddObserver(base::Observer *obs) {
  observers_.AddObserver(obs);
}
void QuickjsRuntime::RemoveObserver(base::Observer *obs) {
  observers_.RemoveObserver(obs);
}

void QuickjsRuntime::Finalize() { observers_.ForEachObserver(); }

void QuickjsRuntime::SetDebugViewId(int view_id) { debug_view_id_ = view_id; }

void QuickjsRuntime::RequestGC() {
  LOGI("RequestGC");
  if (auto rt = getJSRuntime()) {
    LEPUS_RunGC(rt);
  }
}

std::unique_ptr<piper::Runtime> makeQuickJsRuntime() {
  return std::make_unique<QuickjsRuntime>();
}

}  // namespace piper
}  // namespace lynx
