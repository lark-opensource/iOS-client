/**
 * Copyright (c) 2017 Node.js API collaborators. All Rights Reserved.
 *
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file in the root of the source tree.
 */

#include "js_native_api_QuickJS.h"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <codecvt>
#include <cstring>
#include <functional>
#include <locale>
#include <mutex>
#include <stdexcept>
#include <string>
#include <vector>

#include "basic/log/logging.h"
#include "napi_env_quickjs.h"
#include "quickjs_id.h"

#define DECLARE_METHOD(API) \
  static std::remove_pointer<decltype(napi_env__::napi_##API)>::type napi_##API;

FOR_EACH_NAPI_ENGINE_CALL(DECLARE_METHOD)

#undef DECLARE_METHOD

struct napi_callback_info__qjs {
  napi_value newTarget;
  napi_value thisArg;
  napi_value* argv;
  void* data;
  uint16_t argc;
};

struct LEPUSStackFrame* GetStackFrame(LEPUSContext* ctx);

namespace {
napi_status napi_set_exception(napi_env env, LEPUSValue exception) {
  if (env->ctx->last_exception) {
    LEPUS_FreeValue(env->ctx->ctx, *env->ctx->last_exception);
  }
  env->ctx->last_exception.reset(new LEPUSValue(exception));
  return napi_set_last_error(env, napi_pending_exception);
}

napi_status napi_set_error_msg_code(napi_env env, napi_value error,
                                    napi_value code, napi_value msg,
                                    const char* code_cstring) {
  {
    LEPUSValue msg_value = LEPUS_DupValue(env->ctx->ctx, ToJSValue(msg));

    CHECK_QJS(env, LEPUS_SetProperty(env->ctx->ctx, ToJSValue(error),
                                     env->ctx->PROP_MESSAGE, msg_value) != -1);
  }

  if (code || code_cstring) {
    LEPUSValue code_value;
    if (code == nullptr) {
      code_value = LEPUS_NewString(env->ctx->ctx, code_cstring);
    } else {
      code_value = ToJSValue(code);
      RETURN_STATUS_IF_FALSE(env, LEPUS_IsString(code_value),
                             napi_string_expected);
      code_value = LEPUS_DupValue(env->ctx->ctx, code_value);
    }

    CHECK_QJS(env, LEPUS_SetProperty(env->ctx->ctx, ToJSValue(error),
                                     env->ctx->PROP_CODE, code_value) != -1);
  }

  return napi_ok;
}

template <typename In, typename Out, Out Convert(In*)>
class ArgsConverter {
 public:
  ArgsConverter(size_t argc, In* argv) {
    Out* destination = inline_;
    if (argc > maxStackArgs) {
      outOfLine_ = std::make_unique<Out[]>(argc);
      destination = outOfLine_.get();
    }

    for (size_t i = 0; i < argc; ++i) {
      destination[i] = Convert(argv + i);
    }
  }

  operator Out*() { return outOfLine_ ? outOfLine_.get() : inline_; }

 private:
  constexpr static unsigned maxStackArgs = 8;
  Out inline_[maxStackArgs];
  std::unique_ptr<Out[]> outOfLine_;
};
}  // namespace

namespace qjsimpl {

inline LEPUSValue Persistent::Value() {
  return LEPUS_DupValue(_env->ctx->ctx, _value);
}

inline Persistent::Persistent(napi_env env, LEPUSValueConst value,
                              NativeInfo* native_info)
    : _env(env),
      _empty(false),
      _value(LEPUS_DupValue(env->ctx->ctx, value)),
      _native_info(native_info) {}

inline void Persistent::Reset(napi_env env, LEPUSValueConst value,
                              NativeInfo* native_info) {
  Reset();
  _empty = false;
  _env = env;
  _value = LEPUS_DupValue(env->ctx->ctx, value);
  _native_info = native_info;
}

inline void Persistent::Reset() {
  if (_empty) {
    return;
  }
  if (_weak_info) {
    ResetWeakInfo();
  } else {
    LEPUS_FreeValue(_env->ctx->ctx, _value);
  }

  _env = nullptr;
  _empty = true;
  _native_info = nullptr;
}

enum NativeType { External, Wrapper };

class NativeInfo final {
 public:
  NativeInfo(napi_env env, NativeType type)
      : _env(env), _type(type), _data(nullptr) {}

  std::list<Persistent*>::const_iterator AddWeakRef(Persistent* ref) {
    return _weakRefs.insert(_weakRefs.end(), ref);
  }

  void RemoveWeakRef(std::list<Persistent*>::const_iterator iter) {
    _weakRefs.erase(iter);
  }

  napi_env Env() const { return _env; }

  void Data(void* value) { _data = value; }

  void* Data() const { return _data; }

  NativeType Type() const { return _type; }

  static bool IsInstance(LEPUSClassID id) { return id == class_id; }

  static NativeInfo* Get(LEPUSValue val) {
    return static_cast<NativeInfo*>(LEPUS_GetOpaque(val, class_id));
  }

  static LEPUSClassID ClassId(napi_env env) {
    static std::once_flag once_flag;
    std::call_once(once_flag, [&] { LEPUS_NewClassID(&class_id); });

    if (!LEPUS_IsRegisteredClass(env->ctx->rt, class_id)) {
      static LEPUSClassDef def = {.class_name = "NAPIMagicNative",
                                  .finalizer = NativeInfo::OnFinalize};
      if (LEPUS_NewClass(env->ctx->rt, class_id, &def) != 0) {
        return 0;
      }
    }

    return class_id;
  }

 private:
  ~NativeInfo() {
    // ref will remove itself when finalize, so copy is needed
    for (Persistent* ref :
         std::vector<Persistent*>(std::begin(_weakRefs), std::end(_weakRefs))) {
      Persistent::OnFinalize(ref);
    }
  }

 private:
  const napi_env _env;
  const NativeType _type;

  void* _data;
  std::list<Persistent*> _weakRefs;

  static LEPUSClassID class_id;

  static void OnFinalize(LEPUSRuntime* rt, LEPUSValue val) {
    NativeInfo* info = static_cast<NativeInfo*>(LEPUS_GetOpaque(val, class_id));
    LEPUS_SetOpaque(val, nullptr);
    delete info;
  }
};

LEPUSClassID NativeInfo::class_id = 0;

class External {
 public:
  static LEPUSValue Create(napi_env env, NativeInfo** result) {
    LEPUSClassID id = NativeInfo::ClassId(env);
    if (!id) {
      return LEPUS_ThrowInternalError(env->ctx->ctx,
                                      "failed to create External Class");
    }
    LEPUSValue object = LEPUS_NewObjectClass(env->ctx->ctx, id);
    if (!LEPUS_IsException(object)) {
      NativeInfo* info = new NativeInfo(env, NativeType::External);
      LEPUS_SetOpaque(object, info);
      *result = info;
    }
    return object;
  }
};

class Wrapper {
 public:
  static LEPUSValue Create(napi_env env, LEPUSValue proto) {
    LEPUSClassID id = NativeInfo::ClassId(env);
    if (!id) {
      return LEPUS_ThrowInternalError(env->ctx->ctx,
                                      "failed to create Wrapper Class");
    }
    LEPUSValue object = LEPUS_NewObjectProtoClass(env->ctx->ctx, proto, id);
    if (!LEPUS_IsException(object)) {
      LEPUS_SetOpaque(object, new NativeInfo(env, NativeType::Wrapper));
    }
    return object;
  }
};

inline void Persistent::SetWeak(void* data, std::function<void(void*)> cb) {
  assert(!_empty);
  if (_weak_info) {
    _weak_info->cb_arg = data;
    _weak_info->cb = cb;
  } else {
    _weak_info.reset(
        new WeakInfo{_get_native_info()->AddWeakRef(this), cb, data});
    LEPUS_FreeValue(_env->ctx->ctx, _value);
  }
}

inline void Persistent::ClearWeak() {
  LEPUS_DupValue(_env->ctx->ctx, _value);
  ResetWeakInfo();
}

inline void Persistent::ResetWeakInfo() {
  assert(!_empty);
  _get_native_info()->RemoveWeakRef(_weak_info->weak_iter);
  _weak_info.reset();
}

inline NativeInfo* Persistent::_get_native_info() {
  assert(!_empty);
  if (!_native_info) {
    LEPUSValue finalizer =
        LEPUS_GetProperty(_env->ctx->ctx, _value, _env->ctx->PROP_FINALIZER);
    assert(!LEPUS_IsException(finalizer));
    if (LEPUS_IsUndefined(finalizer)) {
      NativeInfo* info;
      finalizer = External::Create(_env, &info);
      assert(!LEPUS_IsException(finalizer));
      int ret = LEPUS_DefinePropertyValue(
          _env->ctx->ctx, _value, _env->ctx->PROP_FINALIZER, finalizer, 0);
      (void)ret;
      assert(ret != -1);
      _native_info = info;
    } else {
      _native_info = qjsimpl::NativeInfo::Get(finalizer);
      LEPUS_FreeValue(_env->ctx->ctx, finalizer);
    }
  }
  return _native_info;
}

// Wrapper around v8impl::Persistent that implements reference counting.
class RefBase : protected Finalizer, RefTracker {
 protected:
  RefBase(napi_env env, uint32_t initial_refcount, bool delete_self,
          napi_finalize finalize_callback, void* finalize_data,
          void* finalize_hint)
      : Finalizer(env, finalize_callback, finalize_data, finalize_hint),
        _refcount(initial_refcount),
        _delete_self(delete_self),
        _is_self_destroying(false) {
    Link(finalize_callback == nullptr ? &env->ctx->reflist
                                      : &env->ctx->finalizing_reflist);
  }

 public:
  static RefBase* New(napi_env env, uint32_t initial_refcount, bool delete_self,
                      napi_finalize finalize_callback, void* finalize_data,
                      void* finalize_hint) {
    return new RefBase(env, initial_refcount, delete_self, finalize_callback,
                       finalize_data, finalize_hint);
  }

  virtual ~RefBase() { Unlink(); }

  inline void* Data() { return _finalize_data; }

  // Delete is called in 2 ways. Either from the finalizer or
  // from one of Unwrap or napi_delete_reference.
  //
  // When it is called from Unwrap or napi_delete_reference we only
  // want to do the delete if the finalizer has already run or
  // cannot have been queued to run (ie the reference count is > 0),
  // otherwise we may crash when the finalizer does run.
  // If the finalizer may have been queued and has not already run
  // delay the delete until the finalizer runs by not doing the delete
  // and setting _delete_self to true so that the finalizer will
  // delete it when it runs.
  //
  // The second way this is called is from
  // the finalizer and _delete_self is set. In this case we
  // know we need to do the deletion so just do it.
  static inline void Delete(RefBase* reference) {
    if ((reference->RefCount() != 0) || (reference->_delete_self) ||
        (reference->_finalize_ran)) {
      delete reference;
    } else {
      // defer until finalizer runs as
      // it may alread be queued
      reference->_delete_self = true;
    }
  }

  inline uint32_t Ref() { return ++_refcount; }

  inline uint32_t Unref() {
    if (_refcount == 0) {
      return 0;
    }
    return --_refcount;
  }

  inline uint32_t RefCount() { return _refcount; }

 protected:
  inline void Finalize(bool is_env_teardown = false) override {
    if (is_env_teardown && RefCount() > 0) _refcount = 0;

    // There are cases where we want to avoid the reentrance of Finalize (
    // causing double-free):
    // * When a wrapped object holds its own strong reference (either directly
    //   or indirectly)
    // * (JSCore specific) when the destruction of a strong reference triggers
    //   garbage collection
    // If we are sure this is getting deleted soon, there is no need for the
    // finalizer to proceed.
    if (_is_self_destroying) {
      return;
    }
    if (is_env_teardown && _delete_self) {
      _is_self_destroying = true;
    }

    if (_finalize_callback != nullptr) {
      // This ensures that we never call the finalizer twice.
      napi_finalize fini = _finalize_callback;
      _finalize_callback = nullptr;
      _env->ctx->CallFinalizer(fini, _finalize_data, _finalize_hint);
    }

    // this is safe because if a request to delete the reference
    // is made in the finalize_callback it will defer deletion
    // to this block and set _delete_self to true
    if (_delete_self || is_env_teardown) {
      Delete(this);
    } else {
      _finalize_ran = true;
    }
  }

 private:
  uint32_t _refcount;
  bool _delete_self;
  bool _is_self_destroying;
};

class Reference : public RefBase {
 protected:
  template <typename... Args>
  Reference(napi_env env, LEPUSValueConst value, NativeInfo* native_info,
            Args&&... args)
      : RefBase(env, std::forward<Args>(args)...),
        _persistent(env, value, native_info) {
    if (RefCount() == 0) {
      _persistent.SetWeak(this, FinalizeCallback);
    }
  }

 public:
  static inline Reference* New(napi_env env, LEPUSValueConst value,
                               NativeInfo* native_info,
                               uint32_t initial_refcount, bool delete_self,
                               napi_finalize finalize_callback = nullptr,
                               void* finalize_data = nullptr,
                               void* finalize_hint = nullptr) {
    return new Reference(env, value, native_info, initial_refcount, delete_self,
                         finalize_callback, finalize_data, finalize_hint);
  }

  inline uint32_t Ref() {
    uint32_t refcount = RefBase::Ref();
    if (refcount == 1) {
      _persistent.ClearWeak();
    }
    return refcount;
  }

  inline uint32_t Unref() {
    uint32_t old_refcount = RefCount();
    uint32_t refcount = RefBase::Unref();
    if (old_refcount == 1 && refcount == 0) {
      _persistent.SetWeak(this, FinalizeCallback);
    }
    return refcount;
  }

  inline napi_value Get() {
    return _persistent.IsEmpty() ? nullptr
                                 : _env->ctx->CreateHandle(_persistent.Value());
  }

 private:
  static void FinalizeCallback(void* data) {
    Reference* r = static_cast<Reference*>(data);
    r->_persistent.Reset();
    r->Finalize();
  }

  Persistent _persistent;
};

enum WrapType { retrievable, anonymous };

template <WrapType wrap_type>
inline napi_status Wrap(napi_env env, napi_value js_object, void* native_object,
                        napi_finalize finalize_cb, void* finalize_hint,
                        napi_ref* result) {
  LEPUSValueConst obj = ToJSValue(js_object);

  NativeInfo* info = NativeInfo::Get(obj);

  if (wrap_type == retrievable) {
    RETURN_STATUS_IF_FALSE(env,
                           info != nullptr &&
                               info->Type() == NativeType::Wrapper &&
                               info->Data() == nullptr,
                           napi_invalid_arg);
  } else {
    // If no finalize callback is provided, we error out.
    CHECK_ARG(env, finalize_cb);
  }

  Reference* reference = nullptr;
  if (result != nullptr) {
    // The returned reference should be deleted via napi_delete_reference()
    // ONLY in response to the finalize callback invocation. (If it is deleted
    // before then, then the finalize callback will never be invoked.)
    // Therefore a finalize callback is required when returning a reference.
    CHECK_ARG(env, finalize_cb);
    reference = Reference::New(env, obj, info, 0, false, finalize_cb,
                               native_object, finalize_hint);
    *result = reinterpret_cast<napi_ref>(reference);
  } else {
    // Create a self-deleting reference.
    reference =
        Reference::New(env, obj, info, 0, true, finalize_cb, native_object,
                       finalize_cb == nullptr ? nullptr : finalize_hint);
  }

  if (wrap_type == retrievable) {
    info->Data(reference);
  }

  return napi_clear_last_error(env);
}

enum UnwrapAction { KeepWrap, RemoveWrap };

inline static napi_status Unwrap(napi_env env, napi_value js_object,
                                 void** result, UnwrapAction action) {
  if (action == KeepWrap) {
    CHECK_ARG(env, result);
  }

  LEPUSValue obj = ToJSValue(js_object);
  NativeInfo* info = NativeInfo::Get(obj);

  if (!info || info->Type() != qjsimpl::NativeType::Wrapper) {
    if (result) {
      *result = nullptr;
    }
    return napi_clear_last_error(env);
  }

  Reference* reference = static_cast<Reference*>(info->Data());

  if (result) {
    *result = reference->Data();
  }

  if (action == RemoveWrap) {
    info->Data(nullptr);
    Reference::Delete(reference);
  }

  return napi_clear_last_error(env);
}

inline static Atom qjsAtomFromPropertyDescriptor(
    napi_env env, const napi_property_descriptor& p) {
  if (p.utf8name != nullptr) {
    return Atom(env->ctx->ctx, p.utf8name);
  } else {
    return Atom(env->ctx->ctx, ToJSValue(p.name));
  }
}

inline static uint8_t qjsFlagFromPropertyDescriptor(
    napi_property_attributes attributes) {
  uint8_t flags = 0;
  if (attributes & napi_writable) {
    flags |= LEPUS_PROP_WRITABLE;
  }
  if (attributes & napi_enumerable) {
    flags |= LEPUS_PROP_ENUMERABLE;
  }
  if (attributes & napi_configurable) {
    flags |= LEPUS_PROP_CONFIGURABLE;
  }
  return flags;
}
}  // namespace qjsimpl

namespace {
static inline LEPUSValue CallJSFunctionWithNAPI(napi_env env, napi_callback cb,
                                                napi_callback_info cbinfo) {
  napi_value result;
  std::unique_ptr<LEPUSValue> exception;
  env->ctx->CallIntoModule([&](napi_env env) { result = cb(env, cbinfo); },
                           [&](napi_env env, LEPUSValue exc) {
                             exception.reset(new LEPUSValue(exc));
                           });

  if (exception) {
    return LEPUS_Throw(env->ctx->ctx, *exception);
  }

  return result ? LEPUS_DupValue(env->ctx->ctx, ToJSValue(result))
                : LEPUS_UNDEFINED;
}
}  // namespace

napi_status napi_create_function(napi_env env, const char* utf8name,
                                 size_t length, napi_callback cb,
                                 void* callback_data, napi_value* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue data[] = {
      LEPUS_MKPTR(LEPUS_TAG_LEPUS_CPOINTER, env),
      LEPUS_MKPTR(LEPUS_TAG_LEPUS_CPOINTER, reinterpret_cast<void*>(cb)),
      LEPUS_MKPTR(LEPUS_TAG_LEPUS_CPOINTER, callback_data)};
  LEPUSValue fun = LEPUS_NewCFunctionData(
      ctx,
      [](LEPUSContext* ctx, LEPUSValueConst this_val, int argc,
         LEPUSValueConst* argv, int magic,
         LEPUSValue* func_data) -> LEPUSValue {
        napi_env env =
            reinterpret_cast<napi_env>(LEPUS_VALUE_GET_PTR(func_data[0]));
        napi_callback cb =
            reinterpret_cast<napi_callback>(LEPUS_VALUE_GET_PTR(func_data[1]));
        void* callback_data = LEPUS_VALUE_GET_PTR(func_data[2]);

        napi_clear_last_error(env);

        qjsimpl::HandleScope scope(env);

        ArgsConverter<LEPUSValueConst, napi_value, ToNapi> args(argc, argv);

        napi_callback_info__qjs cbinfo{};
        cbinfo.thisArg = ToNapi(&this_val);
        cbinfo.newTarget = nullptr;
        cbinfo.argc = argc;
        cbinfo.argv = args;
        cbinfo.data = callback_data;

        return CallJSFunctionWithNAPI(env, cb, &cbinfo);
      },
      0, 0, 3, data);
  CHECK_QJS(env, !LEPUS_IsException(fun));

  if (utf8name) {
    // ignore error
    LEPUS_SetProperty(ctx, fun, env->ctx->PROP_NAME,
                      LEPUS_NewString(ctx, utf8name));
  }

  *result = env->ctx->CreateHandle(fun);
  return napi_clear_last_error(env);
}

static std::string GetExceptionMessage(LEPUSContext* ctx,
                                       LEPUSValueConst exception_val) {
  LEPUSValue val;
  const char* stack;
  const char* message = LEPUS_ToCString(ctx, exception_val);
  std::string ret = "quickjs: ";
  if (message) {
    ret += message;
    ret += "\n";
    LEPUS_FreeCString(ctx, message);
  }

  bool is_error = LEPUS_IsError(ctx, exception_val);
  if (is_error) {
    val = LEPUS_GetPropertyStr(ctx, exception_val, "stack");
    if (!LEPUS_IsUndefined(val)) {
      stack = LEPUS_ToCString(ctx, val);
      ret += stack;
      LEPUS_FreeCString(ctx, stack);
    }
    LEPUS_FreeValue(ctx, val);
  }
  return ret;
}

napi_status napi_define_class(napi_env env, const char* utf8name, size_t length,
                              napi_callback cb, void* data,
                              size_t property_count,
                              const napi_property_descriptor* properties,
                              napi_class super_class, napi_class* result) {
  qjsimpl::HandleScope scope(env);

  LEPUSContext* ctx = env->ctx->ctx;

  qjsimpl::Value proto(ctx, super_class
                                ? LEPUS_NewObjectProto(ctx, super_class->proto)
                                : LEPUS_NewObject(ctx));

  CHECK_QJS(env, !LEPUS_IsException(proto));

  struct ClassData {
    napi_callback cb;
    void* data;
    LEPUSValue proto;
  };

  qjsimpl::NativeInfo* ctor_info;
  qjsimpl::Value ctor_magic(ctx, qjsimpl::External::Create(env, &ctor_info));
  CHECK_QJS(env, !LEPUS_IsException(ctor_magic));

  ClassData* ctor_magic_data =
      new ClassData{.cb = cb, .data = data, .proto = proto.dup()};
  ctor_info->Data(ctor_magic_data);
  qjsimpl::Reference::New(
      env, ctor_magic, ctor_info, 0, true,
      [](napi_env env, void* data, void* hint) {
        ClassData* ctor_magic_data = static_cast<ClassData*>(data);
        LEPUS_FreeValue(env->ctx->ctx, ctor_magic_data->proto);
        delete ctor_magic_data;
        static_cast<qjsimpl::NativeInfo*>(hint)->Data(nullptr);
      },
      ctor_magic_data, ctor_info);

  qjsimpl::Value constructor(
      ctx,
      LEPUS_NewCFunctionMagic(
          ctx,
          [](LEPUSContext* ctx, LEPUSValueConst new_target, int argc,
             LEPUSValueConst* argv, int PROP_CTOR_MAGIC) -> LEPUSValue {
            LEPUSValue ctor_magic =
                LEPUS_GetProperty(ctx, new_target, PROP_CTOR_MAGIC);
            if (LEPUS_IsException(ctor_magic) ||
                LEPUS_IsUndefined(ctor_magic)) {
              if (LEPUS_IsObject(new_target)) {
                LOGE("new_target is an object");
              }
              LOGE("new_target ptr is "
                   << LEPUS_VALUE_GET_PTR(new_target) << ", prop_ctor_magic is "
                   << PROP_CTOR_MAGIC << ", exception message: "
                   << GetExceptionMessage(ctx, ctor_magic));
              return ctor_magic;
            }
            qjsimpl::NativeInfo* info = qjsimpl::NativeInfo::Get(ctor_magic);
            LEPUS_FreeValue(ctx, ctor_magic);
            if (!(info != nullptr &&
                  info->Type() == qjsimpl::NativeType::External &&
                  info->Data())) {
              LOGE("ctor_magic native_info error return undefined, info is "
                   << info);
              return LEPUS_UNDEFINED;
            }
            napi_env env = info->Env();
            ClassData* class_data = static_cast<ClassData*>(info->Data());
            LEPUSValue this_val =
                qjsimpl::Wrapper::Create(env, class_data->proto);

            if (LEPUS_IsException(this_val)) {
              LOGE("create Wrapper return exception");
              return this_val;
            }
            napi_clear_last_error(env);

            qjsimpl::HandleScope scope(env);

            ArgsConverter<LEPUSValueConst, napi_value, ToNapi> args(argc, argv);

            napi_callback_info__qjs cbinfo{};
            cbinfo.thisArg = env->ctx->CreateHandle(this_val);
            cbinfo.newTarget = ToNapi(&new_target);
            cbinfo.argc = argc;
            cbinfo.argv = args;
            cbinfo.data = class_data->data;

            auto result = CallJSFunctionWithNAPI(env, class_data->cb, &cbinfo);
            if (LEPUS_IsUndefined(result)) {
              LOGE("napi callback return undefined");
            }
            return result;
          },
          utf8name, 0, LEPUS_CFUNC_constructor_magic,
          env->ctx->PROP_CTOR_MAGIC));

  //  CHECK_QJS(env, !LEPUS_IsException(constructor));
  if (LEPUS_IsException(constructor)) {
    napi_status status =
        napi_set_exception(env, LEPUS_GetException(env->ctx->ctx));
    LOGE(GetExceptionMessage(env->ctx->ctx, *env->ctx->last_exception));
    return status;
  }

  //  CHECK_QJS(env, LEPUS_DefinePropertyValue(ctx, constructor,
  //                                           env->ctx->PROP_CTOR_MAGIC,
  //                                           ctor_magic.move(), 0) != -1);
  if (LEPUS_DefinePropertyValue(ctx, constructor, env->ctx->PROP_CTOR_MAGIC,
                                ctor_magic.move(), 0) == -1) {
    napi_status status =
        napi_set_exception(env, LEPUS_GetException(env->ctx->ctx));
    LOGE(GetExceptionMessage(env->ctx->ctx, *env->ctx->last_exception));
    return status;
  }
  LOGE("class name is " << utf8name << ", constructor ptr is "
                        << LEPUS_VALUE_GET_PTR(LEPUSValueConst(constructor))
                        << ", prop_ctor_magic is "
                        << LEPUSAtom(env->ctx->PROP_CTOR_MAGIC));

  if (super_class) {
    CHECK_QJS(env, LEPUS_SetPrototype(ctx, constructor,
                                      super_class->constructor) != -1);
  }

  CHECK_QJS(
      env, LEPUS_DefinePropertyValue(ctx, constructor, env->ctx->PROP_PROTOTYPE,
                                     proto.dup(), 0) != -1);
  CHECK_QJS(env, LEPUS_DefinePropertyValue(
                     ctx, proto, env->ctx->PROP_CONSTRUCTOR, constructor.dup(),
                     LEPUS_PROP_WRITABLE | LEPUS_PROP_CONFIGURABLE) != -1);

  int instancePropertyCount{0};
  int staticPropertyCount{0};
  for (size_t i = 0; i < property_count; i++) {
    if ((properties[i].attributes & napi_static) != 0) {
      staticPropertyCount++;
    } else {
      instancePropertyCount++;
    }
  }

  std::vector<napi_property_descriptor> staticDescriptors{};
  std::vector<napi_property_descriptor> instanceDescriptors{};
  staticDescriptors.reserve(staticPropertyCount);
  instanceDescriptors.reserve(instancePropertyCount);

  for (size_t i = 0; i < property_count; i++) {
    if ((properties[i].attributes & napi_static) != 0) {
      staticDescriptors.push_back(properties[i]);
    } else {
      instanceDescriptors.push_back(properties[i]);
    }
  }

  if (staticPropertyCount > 0) {
    LEPUSValue ctor_val = constructor;

    CHECK_NAPI(napi_define_properties(env, ToNapi(&ctor_val),
                                      staticDescriptors.size(),
                                      staticDescriptors.data()));
  }

  if (instancePropertyCount > 0) {
    LEPUSValue proto_val = proto;

    CHECK_NAPI(napi_define_properties(env, ToNapi(&proto_val),
                                      instanceDescriptors.size(),
                                      instanceDescriptors.data()));
  }

  *result = new napi_class__qjs(ctx, proto.move(), constructor.move());

  return napi_clear_last_error(env);
}

napi_status napi_release_class(napi_env env, napi_class clazz) {
  delete clazz;
  return napi_clear_last_error(env);
}

napi_status napi_class_get_function(napi_env env, napi_class clazz,
                                    napi_value* result) {
  *result = env->ctx->CreateHandle(clazz->GetFunction());
  return napi_clear_last_error(env);
}

napi_status napi_get_property_names(napi_env env, napi_value object,
                                    napi_value* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSPropertyEnum* props;
  uint32_t props_length;
  CHECK_QJS(env, LEPUS_GetOwnPropertyNames(
                     ctx, &props, &props_length, ToJSValue(object),
                     LEPUS_GPN_STRING_MASK | LEPUS_GPN_SYMBOL_MASK |
                         LEPUS_GPN_ENUM_ONLY | LEPUS_PROP_THROW) != -1);

  std::vector<LEPUSValue> values;
  values.reserve(props_length);
  for (uint32_t i = 0; i < props_length; i++) {
    values[i] = LEPUS_AtomToValue(ctx, props[i].atom);
    LEPUS_FreeAtom(ctx, props[i].atom);
  }
  lepus_free(ctx, props);
  LEPUSValue arr = LEPUS_NewArrayWithValue(ctx, props_length, values.data());
  for (LEPUSValue v : values) {
    LEPUS_FreeValue(ctx, v);
  }

  CHECK_QJS(env, !LEPUS_IsException(arr));
  *result = env->ctx->CreateHandle(arr);
  return napi_clear_last_error(env);
}

napi_status napi_set_property(napi_env env, napi_value object, napi_value key,
                              napi_value value) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, ToJSValue(key));
  CHECK_QJS(env, prop_atom.IsValid());
  int result = LEPUS_SetProperty(ctx, obj, prop_atom,
                                 LEPUS_DupValue(ctx, ToJSValue(value)));
  CHECK_QJS(env, result != -1);
  return napi_clear_last_error(env);
}

napi_status napi_has_property(napi_env env, napi_value object, napi_value key,
                              bool* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, ToJSValue(key));
  CHECK_QJS(env, prop_atom.IsValid());
  int result_has = LEPUS_HasProperty(ctx, obj, prop_atom);
  CHECK_QJS(env, result_has != -1);
  *result = result_has;
  return napi_clear_last_error(env);
}

napi_status napi_get_property(napi_env env, napi_value object, napi_value key,
                              napi_value* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, ToJSValue(key));
  CHECK_QJS(env, prop_atom.IsValid());
  LEPUSValue val = LEPUS_GetProperty(ctx, obj, prop_atom);
  CHECK_QJS(env, !LEPUS_IsException(val));
  *result = env->ctx->CreateHandle(val);
  return napi_clear_last_error(env);
}

napi_status napi_delete_property(napi_env env, napi_value object,
                                 napi_value key, bool* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, ToJSValue(key));
  CHECK_QJS(env, prop_atom.IsValid());
  int result_delete =
      LEPUS_DeleteProperty(ctx, obj, prop_atom, LEPUS_PROP_THROW);
  CHECK_QJS(env, result_delete != -1);
  *result = result_delete;
  return napi_clear_last_error(env);
}

napi_status napi_has_own_property(napi_env env, napi_value object,
                                  napi_value key, bool* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, ToJSValue(key));
  CHECK_QJS(env, prop_atom.IsValid());
  int result_has = LEPUS_GetOwnProperty(ctx, nullptr, obj, prop_atom);
  CHECK_QJS(env, result_has != -1);
  *result = result_has;
  return napi_clear_last_error(env);
}

napi_status napi_set_named_property(napi_env env, napi_value object,
                                    const char* utf8name, napi_value value) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, LEPUS_NewAtom(ctx, utf8name));
  CHECK_QJS(env, prop_atom.IsValid());
  int result = LEPUS_SetProperty(ctx, obj, prop_atom,
                                 LEPUS_DupValue(ctx, ToJSValue(value)));
  CHECK_QJS(env, result != -1);
  return napi_clear_last_error(env);
}

napi_status napi_has_named_property(napi_env env, napi_value object,
                                    const char* utf8name, bool* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, utf8name);
  CHECK_QJS(env, prop_atom.IsValid());
  int result_has = LEPUS_HasProperty(ctx, obj, prop_atom);
  CHECK_QJS(env, result_has != -1);
  *result = result_has;
  return napi_clear_last_error(env);
}

napi_status napi_get_named_property(napi_env env, napi_value object,
                                    const char* utf8name, napi_value* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, utf8name);
  CHECK_QJS(env, prop_atom.IsValid());
  LEPUSValue val = LEPUS_GetProperty(ctx, obj, prop_atom);
  CHECK_QJS(env, !LEPUS_IsException(val));
  *result = env->ctx->CreateHandle(val);
  return napi_clear_last_error(env);
}

napi_status napi_set_element(napi_env env, napi_value object, uint32_t index,
                             napi_value value) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  int result = LEPUS_SetPropertyUint32(ctx, obj, index,
                                       LEPUS_DupValue(ctx, ToJSValue(value)));
  CHECK_QJS(env, result != -1);
  return napi_clear_last_error(env);
}

napi_status napi_has_element(napi_env env, napi_value object, uint32_t index,
                             bool* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  LEPUSValue val = LEPUS_GetPropertyUint32(ctx, obj, index);
  CHECK_QJS(env, !LEPUS_IsException(val));
  *result = !LEPUS_IsUndefined(val);
  LEPUS_FreeValue(ctx, val);
  return napi_clear_last_error(env);
}

napi_status napi_get_element(napi_env env, napi_value object, uint32_t index,
                             napi_value* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  LEPUSValue val = LEPUS_GetPropertyUint32(ctx, obj, index);

  CHECK_QJS(env, !LEPUS_IsException(val));
  *result = env->ctx->CreateHandle(val);
  return napi_clear_last_error(env);
}

napi_status napi_delete_element(napi_env env, napi_value object, uint32_t index,
                                bool* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);
  qjsimpl::Atom prop_atom(ctx, LEPUS_NewAtomUInt32(ctx, index));
  CHECK_QJS(env, prop_atom.IsValid());
  int result_delete =
      LEPUS_DeleteProperty(ctx, obj, prop_atom, LEPUS_PROP_THROW);
  CHECK_QJS(env, result_delete != -1);
  *result = result_delete;
  return napi_clear_last_error(env);
}

napi_status napi_define_properties(napi_env env, napi_value object,
                                   size_t property_count,
                                   const napi_property_descriptor* properties) {
  if (property_count > 0) {
    CHECK_ARG(env, properties);
  }

  qjsimpl::HandleScope scope(env);
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue obj = ToJSValue(object);

  for (size_t i = 0; i < property_count; i++) {
    const napi_property_descriptor& p = properties[i];
    qjsimpl::Atom prop_atom = qjsimpl::qjsAtomFromPropertyDescriptor(env, p);
    CHECK_QJS(env, prop_atom.IsValid());
    uint8_t flags = qjsimpl::qjsFlagFromPropertyDescriptor(p.attributes);
    if (p.getter != nullptr || p.setter != nullptr) {
      LEPUSValue getter = LEPUS_UNDEFINED;
      if (p.getter) {
        napi_value napi_getter;
        CHECK_NAPI(napi_create_function(env, p.utf8name, NAPI_AUTO_LENGTH,
                                        p.getter, p.data, &napi_getter));
        getter = LEPUS_DupValue(ctx, ToJSValue(napi_getter));
      }
      LEPUSValue setter = LEPUS_UNDEFINED;
      if (p.setter) {
        napi_value napi_setter;
        CHECK_NAPI(napi_create_function(env, p.utf8name, NAPI_AUTO_LENGTH,
                                        p.setter, p.data, &napi_setter));
        setter = LEPUS_DupValue(ctx, ToJSValue(napi_setter));
      }
      CHECK_QJS(env, LEPUS_DefinePropertyGetSet(ctx, obj, prop_atom, getter,
                                                setter, flags) != -1);
    } else if (p.method != nullptr) {
      napi_value method;
      CHECK_NAPI(napi_create_function(env, p.utf8name, NAPI_AUTO_LENGTH,
                                      p.method, p.data, &method));
      CHECK_QJS(env, LEPUS_DefinePropertyValue(
                         ctx, obj, prop_atom,
                         LEPUS_DupValue(ctx, ToJSValue(method)), flags) != -1);
    } else {
      LEPUSValue value = LEPUS_DupValue(ctx, ToJSValue(p.value));
      CHECK_QJS(env, LEPUS_DefinePropertyValue(ctx, obj, prop_atom, value,
                                               flags) != -1);
    }
  }

  return napi_clear_last_error(env);
}

napi_status napi_is_array(napi_env env, napi_value value, bool* result) {
  int result_is = LEPUS_IsArray(env->ctx->ctx, ToJSValue(value));
  CHECK_QJS(env, result_is != -1);
  *result = result_is;
  return napi_clear_last_error(env);
}

napi_status napi_get_array_length(napi_env env, napi_value value,
                                  uint32_t* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  LEPUSValue v =
      LEPUS_GetProperty(ctx, ToJSValue(value), env->ctx->PROP_LENGTH);
  CHECK_QJS(env, !LEPUS_IsException(v));
  int result_toint = LEPUS_ToUint32(ctx, result, v);
  LEPUS_FreeValue(ctx, v);
  CHECK_QJS(env, result_toint != -1);
  return napi_clear_last_error(env);
}

napi_status napi_equals(napi_env env, napi_value lhs, napi_value rhs,
                        bool* result) {
  LEPUSValue a = ToJSValue(lhs);
  LEPUSValue b = ToJSValue(rhs);

  *result = LEPUS_SameValue(env->ctx->ctx, a, b);
  return napi_clear_last_error(env);
}

napi_status napi_strict_equals(napi_env env, napi_value lhs, napi_value rhs,
                               bool* result) {
  LEPUSValue a = ToJSValue(lhs);
  LEPUSValue b = ToJSValue(rhs);
  LEPUSContext* ctx = env->ctx->ctx;
  *result = LEPUS_StrictEq(env->ctx->ctx, LEPUS_DupValue(ctx, a),
                           LEPUS_DupValue(ctx, b));
  return napi_clear_last_error(env);
}

napi_status napi_get_prototype(napi_env env, napi_value object,
                               napi_value* result) {
  LEPUSValueConst prototype =
      LEPUS_GetPrototype(env->ctx->ctx, ToJSValue(object));
  CHECK_QJS(env, !LEPUS_IsException(prototype));
  *result = env->ctx->CreateHandle(LEPUS_DupValue(env->ctx->ctx, prototype));
  return napi_clear_last_error(env);
}

napi_status napi_create_object(napi_env env, napi_value* result) {
  LEPUSValue object = LEPUS_NewObject(env->ctx->ctx);
  CHECK_QJS(env, !LEPUS_IsException(object));
  *result = env->ctx->CreateHandle(object);
  return napi_clear_last_error(env);
}

napi_status napi_create_array(napi_env env, napi_value* result) {
  LEPUSValue array = LEPUS_NewArray(env->ctx->ctx);
  CHECK_QJS(env, !LEPUS_IsException(array));
  *result = env->ctx->CreateHandle(array);
  return napi_clear_last_error(env);
}

napi_status napi_create_array_with_length(napi_env env, size_t length,
                                          napi_value* result) {
  LEPUSValue array = LEPUS_NewArray(env->ctx->ctx);
  CHECK_QJS(env, !LEPUS_IsException(array));
  CHECK_QJS(env,
            LEPUS_SetProperty(env->ctx->ctx, array, env->ctx->PROP_LENGTH,
                              LEPUS_NewInt64(env->ctx->ctx, length)) != -1);
  *result = env->ctx->CreateHandle(array);
  return napi_clear_last_error(env);
}

napi_status napi_create_string_latin1(napi_env env, const char* str,
                                      size_t length, napi_value* result) {
  *result = env->ctx->CreateHandle(
      length == NAPI_AUTO_LENGTH
          ? LEPUS_NewString(env->ctx->ctx, str)
          : LEPUS_NewStringLen(env->ctx->ctx, str, length));
  return napi_clear_last_error(env);
}

napi_status napi_create_string_utf8(napi_env env, const char* str,
                                    size_t length, napi_value* result) {
  *result = env->ctx->CreateHandle(
      length == NAPI_AUTO_LENGTH
          ? LEPUS_NewString(env->ctx->ctx, str)
          : LEPUS_NewStringLen(env->ctx->ctx, str, length));
  return napi_clear_last_error(env);
}

napi_status napi_create_string_utf16(napi_env env, const char16_t* str,
                                     size_t length, napi_value* result) {
  *result = env->ctx->CreateHandle(LEPUS_NewWString(
      env->ctx->ctx, reinterpret_cast<const uint16_t*>(str),
      length == NAPI_AUTO_LENGTH ? std::char_traits<char16_t>::length(str)
                                 : length));
  return napi_clear_last_error(env);
}

napi_status napi_create_double(napi_env env, double value, napi_value* result) {
  *result = env->ctx->CreateHandle(LEPUS_NewFloat64(env->ctx->ctx, value));
  return napi_clear_last_error(env);
}

napi_status napi_create_int32(napi_env env, int32_t value, napi_value* result) {
  *result = env->ctx->CreateHandle(LEPUS_NewInt32(env->ctx->ctx, value));
  return napi_clear_last_error(env);
}

napi_status napi_create_uint32(napi_env env, uint32_t value,
                               napi_value* result) {
  *result = env->ctx->CreateHandle(LEPUS_NewInt64(env->ctx->ctx, value));
  return napi_clear_last_error(env);
}

napi_status napi_create_int64(napi_env env, int64_t value, napi_value* result) {
  *result = env->ctx->CreateHandle(LEPUS_NewInt64(env->ctx->ctx, value));
  return napi_clear_last_error(env);
}

napi_status napi_get_boolean(napi_env env, bool value, napi_value* result) {
  *result = env->ctx->CreateHandle(LEPUS_NewBool(env->ctx->ctx, value));
  return napi_clear_last_error(env);
}

napi_status napi_create_symbol(napi_env env, napi_value description,
                               napi_value* result) {
  qjsimpl::HandleScope scope(env);
  napi_value global{}, symbol_func{}, symbol_value{};
  CHECK_NAPI(napi_get_global(env, &global));
  CHECK_NAPI(napi_get_named_property(env, global, "Symbol", &symbol_func));
  CHECK_NAPI(napi_call_function(env, global, symbol_func, 1, &description,
                                &symbol_value));
  *result = scope.Escape(symbol_value);
  return napi_clear_last_error(env);
}

napi_status napi_create_error(napi_env env, napi_value code, napi_value msg,
                              napi_value* result) {
  LEPUSValue error = LEPUS_NewError(env->ctx->ctx);

  CHECK_NAPI(napi_set_error_msg_code(env, ToNapi(&error), code, msg, nullptr));

  *result = env->ctx->CreateHandle(error);
  return napi_clear_last_error(env);
}

napi_status napi_create_type_error(napi_env env, napi_value code,
                                   napi_value msg, napi_value* result) {
  qjsimpl::HandleScope scope(env);

  napi_value global{}, error_ctor{}, error{};
  CHECK_NAPI(napi_get_global(env, &global));
  CHECK_NAPI(napi_get_named_property(env, global, "TypeError", &error_ctor));
  CHECK_NAPI(napi_new_instance(env, error_ctor, 1, &msg, &error));
  CHECK_NAPI(napi_set_error_msg_code(env, error, code, msg, nullptr));

  *result = scope.Escape(error);
  return napi_clear_last_error(env);
}

napi_status napi_create_range_error(napi_env env, napi_value code,
                                    napi_value msg, napi_value* result) {
  qjsimpl::HandleScope scope(env);

  napi_value global{}, error_ctor{}, error{};
  CHECK_NAPI(napi_get_global(env, &global));
  CHECK_NAPI(napi_get_named_property(env, global, "RangeError", &error_ctor));
  CHECK_NAPI(napi_new_instance(env, error_ctor, 1, &msg, &error));
  CHECK_NAPI(napi_set_error_msg_code(env, error, code, msg, nullptr));

  *result = scope.Escape(error);
  return napi_clear_last_error(env);
}

napi_status napi_typeof(napi_env env, napi_value value,
                        napi_valuetype* result) {
  LEPUSValue v = ToJSValue(value);
  int64_t tag = LEPUS_VALUE_GET_NORM_TAG(v);

  switch (tag) {
    case LEPUS_TAG_INT:
    case LEPUS_TAG_FLOAT64:
      *result = napi_number;
      break;
    case LEPUS_TAG_BIG_INT:
      *result = napi_bigint;
      break;
    case LEPUS_TAG_STRING:
      *result = napi_string;
      break;
    case LEPUS_TAG_SYMBOL:
      *result = napi_symbol;
      break;
    case LEPUS_TAG_NULL:
      *result = napi_null;
      break;
    case LEPUS_TAG_UNDEFINED:
      *result = napi_undefined;
      break;
    case LEPUS_TAG_BOOL:
      *result = napi_boolean;
      break;
    case LEPUS_TAG_OBJECT:
      if (LEPUS_IsFunction(env->ctx->ctx, v)) {
        *result = napi_function;
      } else {
        qjsimpl::NativeInfo* info = qjsimpl::NativeInfo::Get(v);
        if (info && info->Type() == qjsimpl::NativeType::External) {
          *result = napi_external;
        } else {
          *result = napi_object;
        }
      }
      break;
    default:
      // Should not get here unless QuickJS has added some new kind of value.
      return napi_set_last_error(env, napi_invalid_arg);
  }

  return napi_clear_last_error(env);
}

napi_status napi_get_undefined(napi_env env, napi_value* result) {
  *result = ToNapi(&(env->ctx->V_UNDEFINED));
  return napi_clear_last_error(env);
}

napi_status napi_get_null(napi_env env, napi_value* result) {
  *result = ToNapi(&(env->ctx->V_NULL));
  return napi_clear_last_error(env);
}

napi_status napi_get_cb_info(
    napi_env env,               // [in] NAPI environment handle
    napi_callback_info cbinfo,  // [in] Opaque callback-info handle
    size_t* argc,      // [in-out] Specifies the size of the provided argv array
                       // and receives the actual count of args.
    napi_value* argv,  // [out] Array of values
    napi_value* this_arg,  // [out] Receives the JS 'this' arg for the call
    void** data) {         // [out] Receives the data pointer for the callback.
  if (argv != nullptr) {
    CHECK_ARG(env, argc);

    size_t i{0};
    size_t min{std::min(*argc, static_cast<size_t>(cbinfo->argc))};

    for (; i < min; i++) {
      argv[i] = cbinfo->argv[i];
    }

    if (i < *argc) {
      for (; i < *argc; i++) {
        argv[i] = ToNapi(&(env->ctx->V_UNDEFINED));
      }
    }
  }

  if (argc != nullptr) {
    *argc = cbinfo->argc;
  }

  if (this_arg != nullptr) {
    *this_arg = cbinfo->thisArg;
  }

  if (data != nullptr) {
    *data = cbinfo->data;
  }

  return napi_clear_last_error(env);
}

napi_status napi_get_new_target(napi_env env, napi_callback_info cbinfo,
                                napi_value* result) {
  *result = cbinfo->newTarget;
  return napi_clear_last_error(env);
}

namespace {
inline LEPUSValueConst ToJSValue(napi_value* v) { return ToJSValue(*v); }
}  // namespace

napi_status napi_call_function(napi_env env, napi_value recv, napi_value func,
                               size_t argc, const napi_value* argv,
                               napi_value* result) {
  if (argc > 0) {
    CHECK_ARG(env, argv);
  }

  LEPUSContext* ctx = env->ctx->ctx;

  ArgsConverter<napi_value, LEPUSValueConst, ToJSValue> args(
      argc, const_cast<napi_value*>(argv));

  LEPUSValue call_result =
      LEPUS_Call(ctx, ToJSValue(func), recv ? ToJSValue(recv) : LEPUS_UNDEFINED,
                 argc, args);
  CHECK_QJS(env, !LEPUS_IsException(call_result));
  if (!GetStackFrame(ctx)) {
    LEPUSContext* pctx = NULL;
    int result = 0;
    while ((result = LEPUS_ExecutePendingJob(env->ctx->rt, &pctx))) {
      if (result < 0) {
        return napi_set_exception(env, LEPUS_GetException(pctx));
      }
    }
  }
  *result = env->ctx->CreateHandle(call_result);

  return napi_clear_last_error(env);
}

napi_status napi_get_global(napi_env env, napi_value* result) {
  *result = env->ctx->CreateHandle(LEPUS_GetGlobalObject(env->ctx->ctx));
  return napi_clear_last_error(env);
}

napi_status napi_throw_(napi_env env, napi_value error) {
  if (env->ctx->last_exception) {
    LEPUS_FreeValue(env->ctx->ctx, *env->ctx->last_exception);
  }
  env->ctx->last_exception.reset(
      new LEPUSValue(LEPUS_DupValue(env->ctx->ctx, ToJSValue(error))));
  return napi_clear_last_error(env);
}

napi_status napi_throw_error(napi_env env, const char* code, const char* msg) {
  qjsimpl::HandleScope scope(env);
  LEPUSValue code_val = LEPUS_NewString(env->ctx->ctx, code);
  LEPUSValue msg_val = LEPUS_NewString(env->ctx->ctx, msg);

  napi_value error{};
  napi_status ret =
      napi_create_error(env, ToNapi(&code_val), ToNapi(&msg_val), &error);
  LEPUS_FreeValue(env->ctx->ctx, code_val);
  LEPUS_FreeValue(env->ctx->ctx, msg_val);

  CHECK_NAPI(ret);

  return napi_throw_(env, error);
}

napi_status napi_throw_type_error(napi_env env, const char* code,
                                  const char* msg) {
  qjsimpl::HandleScope scope(env);
  LEPUSValue code_val = LEPUS_NewString(env->ctx->ctx, code);
  LEPUSValue msg_val = LEPUS_NewString(env->ctx->ctx, msg);

  napi_value error{};
  napi_status ret =
      napi_create_type_error(env, ToNapi(&code_val), ToNapi(&msg_val), &error);
  LEPUS_FreeValue(env->ctx->ctx, code_val);
  LEPUS_FreeValue(env->ctx->ctx, msg_val);

  CHECK_NAPI(ret);

  return napi_throw_(env, error);
}

napi_status napi_throw_range_error(napi_env env, const char* code,
                                   const char* msg) {
  qjsimpl::HandleScope scope(env);
  LEPUSValue code_val = LEPUS_NewString(env->ctx->ctx, code);
  LEPUSValue msg_val = LEPUS_NewString(env->ctx->ctx, msg);

  napi_value error{};
  napi_status ret =
      napi_create_range_error(env, ToNapi(&code_val), ToNapi(&msg_val), &error);
  LEPUS_FreeValue(env->ctx->ctx, code_val);
  LEPUS_FreeValue(env->ctx->ctx, msg_val);

  CHECK_NAPI(ret);

  return napi_throw_(env, error);
}

napi_status napi_is_error(napi_env env, napi_value value, bool* result) {
  *result = LEPUS_IsError(env->ctx->ctx, ToJSValue(value));

  return napi_clear_last_error(env);
}

napi_status napi_get_value_double(napi_env env, napi_value value,
                                  double* result) {
  int ret = LEPUS_ToFloat64(env->ctx->ctx, result, ToJSValue(value));

  CHECK_QJS(env, ret != -1);

  return napi_clear_last_error(env);
}

napi_status napi_get_value_int32(napi_env env, napi_value value,
                                 int32_t* result) {
  int ret = LEPUS_ToInt32(env->ctx->ctx, result, ToJSValue(value));

  CHECK_QJS(env, ret != -1);

  return napi_clear_last_error(env);
}

napi_status napi_get_value_uint32(napi_env env, napi_value value,
                                  uint32_t* result) {
  int ret = LEPUS_ToUint32(env->ctx->ctx, result, ToJSValue(value));

  CHECK_QJS(env, ret != -1);

  return napi_clear_last_error(env);
}

napi_status napi_get_value_int64(napi_env env, napi_value value,
                                 int64_t* result) {
  int ret = LEPUS_ToInt64(env->ctx->ctx, result, ToJSValue(value));

  CHECK_QJS(env, ret != -1);

  return napi_clear_last_error(env);
}

napi_status napi_get_value_bool(napi_env env, napi_value value, bool* result) {
  *result = LEPUS_ToBool(env->ctx->ctx, ToJSValue(value));

  return napi_clear_last_error(env);
}

// Copies a JavaScript string into a LATIN-1 string buffer. The result is the
// number of bytes (excluding the null terminator) copied into buf.
// A sufficient buffer size should be greater than the length of string,
// reserving space for null terminator.
// If bufsize is insufficient, the string will be truncated and null terminated.
// If buf is NULL, this method returns the length of the string (in bytes)
// via the result parameter.
// The result argument is optional unless buf is NULL.
napi_status napi_get_value_string_latin1(napi_env env, napi_value value,
                                         char* buf, size_t bufsize,
                                         size_t* result) {
  LEPUSValue wstring = LEPUS_ToWString(env->ctx->ctx, ToJSValue(value));

  CHECK_QJS(env, !LEPUS_IsException(wstring));

  size_t length = LEPUS_GetStringLength(env->ctx->ctx, wstring);

  if (buf == nullptr) {
    *result = length;
  } else {
    const char16_t* chars = reinterpret_cast<const char16_t*>(
        LEPUS_GetStringChars(env->ctx->ctx, wstring));
    size_t size{std::min(length, bufsize - 1)};
    for (size_t i = 0; i < size; ++i) {
      const char16_t ch{chars[i]};
      buf[i] = (ch < 256) ? ch : '?';
    }
    buf[size] = '\0';
    if (result != nullptr) {
      *result = size;
    }
  }

  LEPUS_FreeValue(env->ctx->ctx, wstring);

  return napi_clear_last_error(env);
}

// Copies a JavaScript string into a UTF-8 string buffer. The result is the
// number of bytes (excluding the null terminator) copied into buf.
// A sufficient buffer size should be greater than the length of string,
// reserving space for null terminator.
// If bufsize is insufficient, the string will be truncated and null terminated.
// If buf is NULL, this method returns the length of the string (in bytes)
// via the result parameter.
// The result argument is optional unless buf is NULL.
napi_status napi_get_value_string_utf8(napi_env env, napi_value value,
                                       char* buf, size_t bufsize,
                                       size_t* result) {
  size_t length;
  const char* str =
      LEPUS_ToCStringLen(env->ctx->ctx, &length, ToJSValue(value));

  CHECK_QJS(env, str);

  if (buf == nullptr) {
    *result = length;
  } else {
    size_t size{std::min(length, bufsize - 1)};
    std::copy(str, str + size, buf);
    buf[size] = '\0';
    if (result != nullptr) {
      *result = size;
    }
  }

  LEPUS_FreeCString(env->ctx->ctx, str);

  return napi_clear_last_error(env);
}

// Copies a JavaScript string into a UTF-16 string buffer. The result is the
// number of 2-byte code units (excluding the null terminator) copied into buf.
// A sufficient buffer size should be greater than the length of string,
// reserving space for null terminator.
// If bufsize is insufficient, the string will be truncated and null terminated.
// If buf is NULL, this method returns the length of the string (in 2-byte
// code units) via the result parameter.
// The result argument is optional unless buf is NULL.
napi_status napi_get_value_string_utf16(napi_env env, napi_value value,
                                        char16_t* buf, size_t bufsize,
                                        size_t* result) {
  LEPUSValue wstring = LEPUS_ToWString(env->ctx->ctx, ToJSValue(value));

  CHECK_QJS(env, !LEPUS_IsException(wstring));

  size_t length = LEPUS_GetStringLength(env->ctx->ctx, wstring);

  if (buf == nullptr) {
    *result = length;
  } else {
    const char16_t* chars = reinterpret_cast<const char16_t*>(
        LEPUS_GetStringChars(env->ctx->ctx, wstring));
    size_t size{std::min(length, bufsize - 1)};
    std::copy(chars, chars + size, buf);
    buf[size] = '\0';
    if (result != nullptr) {
      *result = size;
    }
  }

  LEPUS_FreeValue(env->ctx->ctx, wstring);

  return napi_clear_last_error(env);
}

napi_status napi_coerce_to_bool(napi_env env, napi_value value,
                                napi_value* result) {
  *result = env->ctx->CreateHandle(LEPUS_NewBool(
      env->ctx->ctx, LEPUS_ToBool(env->ctx->ctx, ToJSValue(value))));
  return napi_clear_last_error(env);
}

napi_status napi_coerce_to_number(napi_env env, napi_value value,
                                  napi_value* result) {
  double number;
  int ret = LEPUS_ToFloat64(env->ctx->ctx, &number, ToJSValue(value));

  CHECK_QJS(env, ret != -1);

  *result = env->ctx->CreateHandle(LEPUS_NewFloat64(env->ctx->ctx, number));
  return napi_clear_last_error(env);
}

napi_status napi_coerce_to_object(napi_env env, napi_value value,
                                  napi_value* result) {
  qjsimpl::HandleScope scope(env);
  napi_value global{}, object_func{}, object_value{};
  CHECK_NAPI(napi_get_global(env, &global));
  CHECK_NAPI(napi_get_named_property(env, global, "Object", &object_func));
  CHECK_NAPI(
      napi_call_function(env, global, object_func, 1, &value, &object_value));
  *result = scope.Escape(object_value);

  return napi_clear_last_error(env);
}

napi_status napi_coerce_to_string(napi_env env, napi_value value,
                                  napi_value* result) {
  LEPUSValue str = LEPUS_ToString(env->ctx->ctx, ToJSValue(value));
  CHECK_QJS(env, !LEPUS_IsException(str));
  *result = env->ctx->CreateHandle(str);
  return napi_clear_last_error(env);
}

napi_status napi_wrap(napi_env env, napi_value js_object, void* native_object,
                      napi_finalize finalize_cb, void* finalize_hint,
                      napi_ref* result) {
  return qjsimpl::Wrap<qjsimpl::retrievable>(
      env, js_object, native_object, finalize_cb, finalize_hint, result);
}

napi_status napi_unwrap(napi_env env, napi_value obj, void** result) {
  return qjsimpl::Unwrap(env, obj, result, qjsimpl::KeepWrap);
}

napi_status napi_remove_wrap(napi_env env, napi_value obj, void** result) {
  return qjsimpl::Unwrap(env, obj, result, qjsimpl::RemoveWrap);
}

napi_status napi_create_external(napi_env env, void* data,
                                 napi_finalize finalize_cb, void* finalize_hint,
                                 napi_value* result) {
  qjsimpl::NativeInfo* info;
  LEPUSValue value = qjsimpl::External::Create(env, &info);

  CHECK_QJS(env, !LEPUS_IsException(value));

  info->Data(data);

  qjsimpl::Reference::New(env, value, info, 0, true, finalize_cb, data,
                          finalize_hint);

  *result = env->ctx->CreateHandle(value);

  return napi_clear_last_error(env);
}

napi_status napi_get_value_external(napi_env env, napi_value value,
                                    void** result) {
  qjsimpl::NativeInfo* info = qjsimpl::NativeInfo::Get(ToJSValue(value));
  *result = info != nullptr && info->Type() == qjsimpl::NativeType::External
                ? info->Data()
                : nullptr;
  return napi_clear_last_error(env);
}

// Set initial_refcount to 0 for a weak reference, >0 for a strong reference.
napi_status napi_create_reference(napi_env env, napi_value value,
                                  uint32_t initial_refcount, napi_ref* result) {
  LEPUSValueConst val = ToJSValue(value);

  if (LEPUS_VALUE_GET_NORM_TAG(val) != LEPUS_TAG_OBJECT) {
    return napi_set_last_error(env, napi_object_expected);
  }

  qjsimpl::Reference* reference = qjsimpl::Reference::New(
      env, val, qjsimpl::NativeInfo::Get(val), initial_refcount, false);
  *result = reinterpret_cast<napi_ref>(reference);

  return napi_clear_last_error(env);
}

// Deletes a reference. The referenced value is released, and may be GC'd
// unless there are other references to it.
napi_status napi_delete_reference(napi_env env, napi_ref ref) {
  qjsimpl::Reference::Delete(reinterpret_cast<qjsimpl::Reference*>(ref));

  return napi_clear_last_error(env);
}

// Increments the reference count, optionally returning the resulting count.
// After this call the reference will be a strong reference because its refcount
// is >0, and the referenced object is effectively "pinned". Calling this when
// the refcount is 0 and the target is unavailable results in an error.
napi_status napi_reference_ref(napi_env env, napi_ref ref, uint32_t* result) {
  qjsimpl::Reference* reference = reinterpret_cast<qjsimpl::Reference*>(ref);
  uint32_t count = reference->Ref();

  if (result != nullptr) {
    *result = count;
  }

  return napi_clear_last_error(env);
}

// Decrements the reference count, optionally returning the resulting count.
// If the result is 0 the reference is now weak and the object may be GC'd at
// any time if there are no other references. Calling this when the refcount
// is already 0 results in an error.
napi_status napi_reference_unref(napi_env env, napi_ref ref, uint32_t* result) {
  qjsimpl::Reference* reference = reinterpret_cast<qjsimpl::Reference*>(ref);

  if (reference->RefCount() == 0) {
    return napi_set_last_error(env, napi_generic_failure);
  }

  uint32_t count = reference->Unref();

  if (result != nullptr) {
    *result = count;
  }

  return napi_clear_last_error(env);
}

// Attempts to get a referenced value. If the reference is weak, the value
// might no longer be available, in that case the call is still successful but
// the result is NULL.
napi_status napi_get_reference_value(napi_env env, napi_ref ref,
                                     napi_value* result) {
  qjsimpl::Reference* reference = reinterpret_cast<qjsimpl::Reference*>(ref);

  *result = reference->Get();
  return napi_clear_last_error(env);
}

// Stub implementation of handle scope apis for QuickLEPUS.
napi_status napi_open_context_scope(napi_env env, napi_context_scope* result) {
  *result = reinterpret_cast<napi_context_scope>(1);
  return napi_clear_last_error(env);
}

// Stub implementation of handle scope apis for QuickJS.
napi_status napi_close_context_scope(napi_env env, napi_context_scope scope) {
  return napi_clear_last_error(env);
}

napi_status napi_open_handle_scope(napi_env env, napi_handle_scope* result) {
  *result = reinterpret_cast<napi_handle_scope>(new qjsimpl::HandleScope(env));
  env->ctx->open_handle_scopes++;
  return napi_clear_last_error(env);
}

napi_status napi_close_handle_scope(napi_env env, napi_handle_scope scope) {
  if (env->ctx->open_handle_scopes == 0) {
    return napi_handle_scope_mismatch;
  }
  env->ctx->open_handle_scopes--;

  delete reinterpret_cast<qjsimpl::HandleScope*>(scope);
  return napi_clear_last_error(env);
}

napi_status napi_open_escapable_handle_scope(
    napi_env env, napi_escapable_handle_scope* result) {
  *result = reinterpret_cast<napi_escapable_handle_scope>(
      new qjsimpl::HandleScope(env));
  env->ctx->open_handle_scopes++;
  return napi_clear_last_error(env);
}

napi_status napi_close_escapable_handle_scope(
    napi_env env, napi_escapable_handle_scope scope) {
  if (env->ctx->open_handle_scopes == 0) {
    return napi_handle_scope_mismatch;
  }
  env->ctx->open_handle_scopes--;

  delete reinterpret_cast<qjsimpl::HandleScope*>(scope);
  return napi_clear_last_error(env);
}

napi_status napi_escape_handle(napi_env env, napi_escapable_handle_scope scope,
                               napi_value escapee, napi_value* result) {
  *result = reinterpret_cast<qjsimpl::HandleScope*>(scope)->Escape(escapee);
  return napi_clear_last_error(env);
}

napi_status napi_new_instance(napi_env env, napi_value constructor, size_t argc,
                              const napi_value* argv, napi_value* result) {
  if (argc > 0) {
    CHECK_ARG(env, argv);
  }

  ArgsConverter<napi_value, LEPUSValueConst, ToJSValue> args(
      argc, const_cast<napi_value*>(argv));

  LEPUSValue instance =
      LEPUS_CallConstructor(env->ctx->ctx, ToJSValue(constructor), argc, args);

  CHECK_QJS(env, !LEPUS_IsException(instance));

  *result = env->ctx->CreateHandle(instance);

  return napi_clear_last_error(env);
}

napi_status napi_instanceof(napi_env env, napi_value object,
                            napi_value constructor, bool* result) {
  int ret = LEPUS_IsInstanceOf(env->ctx->ctx, ToJSValue(object),
                               ToJSValue(constructor));

  CHECK_QJS(env, ret != -1);

  *result = ret;

  return napi_clear_last_error(env);
}

napi_status napi_is_exception_pending(napi_env env, bool* result) {
  *result = (bool)env->ctx->last_exception;
  return napi_clear_last_error(env);
}

napi_status napi_get_and_clear_last_exception(napi_env env,
                                              napi_value* result) {
  if (!env->ctx->last_exception) {
    return napi_get_undefined(env, result);
  } else {
    *result = env->ctx->CreateHandle(*env->ctx->last_exception);
    env->ctx->last_exception.reset();
  }

  return napi_clear_last_error(env);
}

std::string get_lepus_error_stack(LEPUSContext* ctx, LEPUSValue& value) {
  std::string err;
  if (LEPUS_IsError(ctx, value) || LEPUS_IsException(value)) {
    LEPUSValue val = LEPUS_GetPropertyStr(ctx, value, "stack");
    if (!LEPUS_IsUndefined(val)) {
      const char* stack = LEPUS_ToCString(ctx, val);
      if (stack) {
        err.append(stack);
      }
      LEPUS_FreeCString(ctx, stack);
    }
    LEPUS_FreeValue(ctx, val);
  }
  return err;
}

napi_status napi_get_unhandled_rejection_exception(napi_env env,
                                                   napi_value* result) {
  LEPUSContext* ctx = env->ctx->ctx;
  std::string error_result;
  while (LEPUS_MoveUnhandledRejectionToException(ctx)) {
    LEPUSValue exception = LEPUS_GetException(ctx);
    const char* error_message = LEPUS_ToCString(ctx, exception);
    if (error_message) {
      error_result.append("message: ");
      error_result.append(error_message);
    }
    LEPUS_FreeCString(ctx, error_message);

    std::string error_stack = get_lepus_error_stack(ctx, exception);
    error_result.append("\nstack: ");
    error_result.append(error_stack);
    error_result.append("\n");
  }
  LEPUSValue result_lepus = LEPUS_NewString(ctx, error_result.c_str());
  *result = env->ctx->CreateHandle(result_lepus);
  return napi_clear_last_error(env);
}

napi_status napi_get_own_property_descriptor(napi_env env,
                                                    napi_value obj,
                                                    napi_value prop,
                                                    napi_value* result) {
  LEPUSValueConst args[2];
  args[0] = ToJSValue(obj);
  args[1] = ToJSValue(prop);
  LEPUSValue descriptor = lepus_object_getOwnPropertyDescriptor(
      env->ctx->ctx, LEPUS_UNDEFINED, 2, args, 0);
  CHECK_QJS(env, !LEPUS_IsException(descriptor));
  *result = env->ctx->CreateHandle(descriptor);
  return napi_clear_last_error(env);
}

napi_status napi_is_arraybuffer(napi_env env, napi_value value, bool* result) {
  LEPUSClassID id = LEPUS_GetClassID(env->ctx->ctx, ToJSValue(value));
  *result =
      id == LEPUS_CLASS_ARRAY_BUFFER || id == LEPUS_CLASS_SHARED_ARRAY_BUFFER;
  return napi_clear_last_error(env);
}

napi_status napi_create_arraybuffer(napi_env env, size_t byte_length,
                                    void** data, napi_value* result) {
  void* bytes = std::malloc(byte_length);
  // v8 use zero initialized
  std::memset(bytes, 0, byte_length);
  LEPUSValue buffer = LEPUS_NewArrayBuffer(
      env->ctx->ctx, static_cast<uint8_t*>(bytes), byte_length,
      [](LEPUSRuntime* rt, void* opaque, void* ptr) { std::free(ptr); },
      nullptr, false);

  if (LEPUS_IsException(buffer)) {
    std::free(bytes);
    CHECK_QJS(env, false);
  }

  *data = bytes;
  *result = env->ctx->CreateHandle(buffer);

  return napi_clear_last_error(env);
}

napi_status napi_create_external_arraybuffer(napi_env env, void* external_data,
                                             size_t byte_length,
                                             napi_finalize finalize_cb,
                                             void* finalize_hint,
                                             napi_value* result) {
  LEPUSValue buffer = LEPUS_NewArrayBuffer(
      env->ctx->ctx, static_cast<uint8_t*>(external_data), byte_length,
      [](LEPUSRuntime* rt, void* opaque, void* ptr) {}, nullptr, false);

  CHECK_QJS(env, !LEPUS_IsException(buffer));

  if (finalize_cb != nullptr) {
    qjsimpl::Reference::New(env, buffer, nullptr, 0, true, finalize_cb,
                            external_data, finalize_hint);
  }

  *result = env->ctx->CreateHandle(buffer);

  return napi_clear_last_error(env);
}

napi_status napi_get_arraybuffer_info(napi_env env, napi_value arraybuffer,
                                      void** data, size_t* byte_length) {
  size_t size;
  uint8_t* bytes =
      LEPUS_GetArrayBuffer(env->ctx->ctx, &size, ToJSValue(arraybuffer));

  CHECK_QJS(env, bytes);

  if (data) {
    *data = static_cast<void*>(bytes);
  }
  if (byte_length) {
    *byte_length = size;
  }
  return napi_clear_last_error(env);
}

napi_status napi_is_typedarray(napi_env env, napi_value value, bool* result) {
  LEPUSClassID class_id = LEPUS_GetClassID(env->ctx->ctx, ToJSValue(value));
  *result = class_id >= LEPUS_CLASS_UINT8C_ARRAY &&
            class_id <= LEPUS_CLASS_FLOAT64_ARRAY;
  return napi_clear_last_error(env);
}

#define FOR_EACH_TYPEDARRAY(V)                          \
  V(napi_uint8_clamped_array, LEPUS_CLASS_UINT8C_ARRAY) \
  V(napi_uint8_array, LEPUS_CLASS_UINT8_ARRAY)          \
  V(napi_int8_array, LEPUS_CLASS_INT8_ARRAY)            \
  V(napi_int16_array, LEPUS_CLASS_INT16_ARRAY)          \
  V(napi_uint16_array, LEPUS_CLASS_UINT16_ARRAY)        \
  V(napi_int32_array, LEPUS_CLASS_INT32_ARRAY)          \
  V(napi_uint32_array, LEPUS_CLASS_UINT32_ARRAY)        \
  V(napi_float32_array, LEPUS_CLASS_FLOAT32_ARRAY)      \
  V(napi_float64_array, LEPUS_CLASS_FLOAT64_ARRAY)

napi_status napi_create_typedarray(napi_env env, napi_typedarray_type type,
                                   size_t length, napi_value arraybuffer,
                                   size_t byte_offset, napi_value* result) {
  LEPUSClassID class_id;

  switch (type) {
#define CASE_TYPE(TYPE, CLASS_ID) \
  case TYPE:                      \
    class_id = CLASS_ID;          \
    break;

    FOR_EACH_TYPEDARRAY(CASE_TYPE)

#undef CASE_TYPE
    case napi_bigint64_array:
    case napi_biguint64_array:
      return napi_set_last_error(env, napi_invalid_arg);
  }

  LEPUSValue array = LEPUS_NewTypedArrayWithBuffer(
      env->ctx->ctx, ToJSValue(arraybuffer), byte_offset, length, class_id);

  CHECK_QJS(env, !LEPUS_IsException(array));

  *result = env->ctx->CreateHandle(array);

  return napi_clear_last_error(env);
}

napi_status napi_is_typedarray_of(napi_env env, napi_value typedarray,
                                  napi_typedarray_type type, bool* result) {
  LEPUSClassID class_id =
      LEPUS_GetClassID(env->ctx->ctx, ToJSValue(typedarray));

  switch (type) {
#define CASE_TYPE(TYPE, CLASS_ID)   \
  case TYPE:                        \
    *result = class_id == CLASS_ID; \
    break;

    FOR_EACH_TYPEDARRAY(CASE_TYPE)

#undef CASE_TYPE
    case napi_bigint64_array:
    case napi_biguint64_array:
      return napi_set_last_error(env, napi_invalid_arg);
  }

  return napi_clear_last_error(env);
}

napi_status napi_get_typedarray_info(napi_env env, napi_value typedarray,
                                     napi_typedarray_type* type, size_t* length,
                                     void** data, napi_value* arraybuffer,
                                     size_t* byte_offset) {
  LEPUSValueConst typedarray_val = ToJSValue(typedarray);
  LEPUSClassID class_id = LEPUS_GetClassID(env->ctx->ctx, typedarray_val);

  switch (class_id) {
#define CASE_TYPE(TYPE, CLASS_ID) \
  case CLASS_ID:                  \
    if (type) *type = TYPE;       \
    break;

    FOR_EACH_TYPEDARRAY(CASE_TYPE)

#undef CASE_TYPE
    case napi_bigint64_array:
    case napi_biguint64_array:
      return napi_set_last_error(env, napi_invalid_arg);
  }

  uint32_t byte_offset_num;

  {
    LEPUSValue val = LEPUS_GetProperty(env->ctx->ctx, typedarray_val,
                                       env->ctx->PROP_BYTEOFFSET);
    CHECK_QJS(env, !LEPUS_IsException(val));
    CHECK_QJS(env, LEPUS_ToUint32(env->ctx->ctx, &byte_offset_num, val) != -1);
    if (byte_offset) {
      *byte_offset = byte_offset_num;
    }
  }

  if (length) {
    LEPUSValue val =
        LEPUS_GetProperty(env->ctx->ctx, typedarray_val, env->ctx->PROP_LENGTH);
    CHECK_QJS(env, !LEPUS_IsException(val));
    uint32_t length_num;
    CHECK_QJS(env, LEPUS_ToUint32(env->ctx->ctx, &length_num, val) != -1);
    *length = length_num;
  }

  if (data || arraybuffer) {
    LEPUSValue val =
        LEPUS_GetProperty(env->ctx->ctx, typedarray_val, env->ctx->PROP_BUFFER);
    CHECK_QJS(env, !LEPUS_IsException(val));
    if (arraybuffer) {
      *arraybuffer = env->ctx->CreateHandle(val);
    }
    if (data) {
      size_t unused;
      uint8_t* buffer_start = LEPUS_GetArrayBuffer(env->ctx->ctx, &unused, val);
      CHECK_QJS(env, buffer_start);
      *data = buffer_start + byte_offset_num;
    }
  }

  return napi_clear_last_error(env);
}

napi_status napi_create_dataview(napi_env env, size_t byte_length,
                                 napi_value arraybuffer, size_t byte_offset,
                                 napi_value* result) {
  qjsimpl::HandleScope scope(env);
  napi_value global{}, dataview_ctor{}, data_view{};
  CHECK_NAPI(napi_get_global(env, &global));
  CHECK_NAPI(napi_get_named_property(env, global, "DataView", &dataview_ctor));

  napi_value byte_offset_value{}, byte_length_value{};
  napi_create_double(env, static_cast<double>(byte_offset), &byte_offset_value);
  napi_create_double(env, static_cast<double>(byte_length), &byte_length_value);
  napi_value args[] = {arraybuffer, byte_offset_value, byte_length_value};
  CHECK_NAPI(napi_new_instance(env, dataview_ctor, 3, args, &data_view));

  *result = scope.Escape(data_view);

  return napi_clear_last_error(env);
}

napi_status napi_is_dataview(napi_env env, napi_value value, bool* result) {
  LEPUSClassID class_id = LEPUS_GetClassID(env->ctx->ctx, ToJSValue(value));
  *result = class_id == LEPUS_CLASS_DATAVIEW;
  return napi_clear_last_error(env);
}

napi_status napi_get_dataview_info(napi_env env, napi_value dataview,
                                   size_t* byte_length, void** data,
                                   napi_value* arraybuffer,
                                   size_t* byte_offset) {
  LEPUSValueConst dataview_val = ToJSValue(dataview);
  LEPUSClassID class_id = LEPUS_GetClassID(env->ctx->ctx, dataview_val);

  if (class_id != LEPUS_CLASS_DATAVIEW) {
    return napi_set_last_error(env, napi_invalid_arg);
  }

  uint32_t byte_offset_num;

  {
    LEPUSValue val = LEPUS_GetProperty(env->ctx->ctx, dataview_val,
                                       env->ctx->PROP_BYTEOFFSET);
    CHECK_QJS(env, !LEPUS_IsException(val));
    CHECK_QJS(env, LEPUS_ToUint32(env->ctx->ctx, &byte_offset_num, val) != -1);
    if (byte_offset) {
      *byte_offset = byte_offset_num;
    }
  }

  if (byte_length) {
    LEPUSValue val = LEPUS_GetProperty(env->ctx->ctx, dataview_val,
                                       env->ctx->PROP_BYTELENGTH);
    CHECK_QJS(env, !LEPUS_IsException(val));
    uint32_t byte_length_num;
    CHECK_QJS(env, LEPUS_ToUint32(env->ctx->ctx, &byte_length_num, val) != -1);
    *byte_length = byte_length_num;
  }

  if (data || arraybuffer) {
    LEPUSValue val =
        LEPUS_GetProperty(env->ctx->ctx, dataview_val, env->ctx->PROP_BUFFER);
    CHECK_QJS(env, !LEPUS_IsException(val));
    if (arraybuffer) {
      *arraybuffer = env->ctx->CreateHandle(val);
    }
    if (data) {
      size_t unused;
      uint8_t* buffer_start = LEPUS_GetArrayBuffer(env->ctx->ctx, &unused, val);
      CHECK_QJS(env, buffer_start);
      *data = buffer_start + byte_offset_num;
    }
  }

  return napi_clear_last_error(env);
}

struct napi_deferred__qjs {
  qjsimpl::Persistent resolve;
  qjsimpl::Persistent reject;

  bool has_init = false;

  static napi_value Callback(napi_env env, napi_callback_info cbinfo) {
    napi_deferred__qjs* deferred =
        static_cast<napi_deferred__qjs*>(cbinfo->data);
    deferred->has_init = true;
    deferred->resolve.Reset(env, ToJSValue(cbinfo->argv[0]), nullptr);
    deferred->reject.Reset(env, ToJSValue(cbinfo->argv[1]), nullptr);
    return nullptr;
  }
};

napi_status napi_create_promise(napi_env env, napi_deferred* deferred,
                                napi_value* promise) {
  qjsimpl::HandleScope scope(env);
  napi_value global{}, promise_ctor{};
  CHECK_NAPI(napi_get_global(env, &global));
  CHECK_NAPI(napi_get_named_property(env, global, "Promise", &promise_ctor));

  std::unique_ptr<napi_deferred__qjs> deferred_val =
      std::make_unique<napi_deferred__qjs>();
  napi_value executor{}, promise_val{};
  CHECK_NAPI(napi_create_function(env, "executor", NAPI_AUTO_LENGTH,
                                  napi_deferred__qjs::Callback,
                                  deferred_val.get(), &executor));
  CHECK_NAPI(napi_new_instance(env, promise_ctor, 1, &executor, &promise_val));

  if (!deferred_val->has_init) {
    return napi_set_last_error(env, napi_generic_failure);
  }

  *promise = scope.Escape(promise_val);
  *deferred = deferred_val.release();

  return napi_clear_last_error(env);
}

napi_status napi_release_deferred(napi_env env, napi_deferred deferred,
                                  napi_value resolution,
                                  napi_deferred_release_mode mode) {
  std::unique_ptr<napi_deferred__qjs> _(deferred);  // RAII

  switch (mode) {
    case napi_deferred_delete:
      break;
    case napi_deferred_resolve:
    case napi_deferred_reject:
      qjsimpl::Value resolve(env->ctx->ctx, mode == napi_deferred_resolve
                                                ? deferred->resolve.Value()
                                                : deferred->reject.Value());

      LEPUSValue res = ToJSValue(resolution);
      LEPUSContext* ctx = env->ctx->ctx;
      LEPUSValue result = LEPUS_Call(ctx, resolve, LEPUS_UNDEFINED, 1, &res);

      CHECK_QJS(env, !LEPUS_IsException(result));
      if (!GetStackFrame(ctx)) {
        LEPUSContext* pctx = NULL;
        int result = 0;
        while ((result = LEPUS_ExecutePendingJob(env->ctx->rt, &pctx))) {
          if (result < 0) {
            return napi_set_exception(env, LEPUS_GetException(pctx));
          }
        }
      }
      break;
  }

  return napi_clear_last_error(env);
}

napi_status napi_is_promise(napi_env env, napi_value promise,
                            bool* is_promise) {
  qjsimpl::HandleScope scope(env);

  napi_value global{}, promise_ctor{};
  CHECK_NAPI(napi_get_global(env, &global));
  CHECK_NAPI(napi_get_named_property(env, global, "Promise", &promise_ctor));
  CHECK_NAPI(napi_instanceof(env, promise, promise_ctor, is_promise));

  return napi_clear_last_error(env);
}

napi_status napi_run_script(napi_env env, const char* script, size_t length,
                            const char* filename, napi_value* result) {
  if (length == NAPI_AUTO_LENGTH) {
    length = std::strlen(script);
  }
  LEPUSValue result_val =
      LEPUS_Eval(env->ctx->ctx, script, length, filename ? filename : "",
                 LEPUS_EVAL_TYPE_GLOBAL);
 
  CHECK_QJS(env, !LEPUS_IsException(result_val));

  *result = env->ctx->CreateHandle(result_val);
  return napi_clear_last_error(env);
}

#ifdef ENABLE_CODECACHE
napi_status napi_run_script_cache(napi_env env, const char* script,
                                  size_t length, const char* filename,
                                  napi_value* result) {
  if (length == NAPI_AUTO_LENGTH) {
    length = std::strlen(script);
  }

  LEPUSValue result_val = LEPUS_UNINITIALIZED;
  {
    int len = -1;
    const uint8_t* data = nullptr;
    env->napi_get_code_cache(env, filename, &data, &len);
    if (data) {
      // TODO(yang): check whether the script is obsolate
      LOG_TIME_START();
      LEPUSValue top_func =
          LEPUS_EvalBinary(env->ctx->ctx, data, static_cast<size_t>(len),
                           LEPUS_EVAL_BINARY_LOAD_ONLY);
      if (!LEPUS_IsException(top_func) && !LEPUS_IsUndefined(top_func)) {
        LEPUSValue global = LEPUS_GetGlobalObject(env->ctx->ctx);
        result_val = LEPUS_EvalFunction(env->ctx->ctx, top_func, global);
      }
      LOG_TIME_END("----- script eval with cache -----");
    } else if (len == 0) {
      // if len is 0, we need to make cache.
      // if len is -1, someone is modifying the cache, we do not make cache.
      LOG_TIME_START();
      LEPUSValue top_func =
          LEPUS_Eval(env->ctx->ctx, script, length, filename,
                     LEPUS_EVAL_FLAG_COMPILE_ONLY | LEPUS_EVAL_TYPE_GLOBAL);
      CHECK_QJS(env,
                !LEPUS_IsException(top_func) && !LEPUS_IsUndefined(top_func));
      LEPUSValue global = LEPUS_GetGlobalObject(env->ctx->ctx);

      size_t obj_len;
      data = LEPUS_WriteObject(env->ctx->ctx, &obj_len, top_func,
                               LEPUS_WRITE_OBJ_BYTECODE);
      env->napi_store_code_cache(env, filename, data, (int)obj_len);
      lepus_free(env->ctx->ctx, (void*)data);
      result_val = LEPUS_EvalFunction(env->ctx->ctx, top_func, global);
      LOG_TIME_END(
          "---- evaluating %s and making code cache for it lengthed %d -----",
          filename, (int)obj_len);
    }
  }
  if (LEPUS_IsUninitialized(result_val)) {
    LOG_TIME_START();
    result_val = LEPUS_Eval(env->ctx->ctx, script, length,
                            filename ? filename : "", LEPUS_EVAL_TYPE_GLOBAL);
    LOG_TIME_END("----- script eval without cache -----");
  }
  CHECK_QJS(env, !LEPUS_IsException(result_val));

  *result = env->ctx->CreateHandle(result_val);
  return napi_clear_last_error(env);
}
#endif  // ENABLE_CODECACHE

napi_status napi_add_finalizer(napi_env env, napi_value js_object,
                               void* native_object, napi_finalize finalize_cb,
                               void* finalize_hint, napi_ref* result) {
  return qjsimpl::Wrap<qjsimpl::anonymous>(env, js_object, native_object,
                                           finalize_cb, finalize_hint, result);
}

napi_status napi_adjust_external_memory(napi_env env, int64_t change_in_bytes,
                                        int64_t* adjusted_value) {
  // TODO: Determine if QJS needs or is able to do anything here
  // For now, we can lie and say that we always adjusted more memory
  *adjusted_value = change_in_bytes;

  return napi_clear_last_error(env);
}

napi_status napi_set_instance_data(napi_env env, uint64_t key, void* data,
                                   napi_finalize finalize_cb,
                                   void* finalize_hint) {
  auto it = env->ctx->instance_data_registry.find(key);
  if (it != env->ctx->instance_data_registry.end()) {
    return napi_conflict_instance_data;
  }

  env->ctx->instance_data_registry[key] =
      qjsimpl::RefBase::New(env, 0, true, finalize_cb, data, finalize_hint);

  return napi_clear_last_error(env);
}

napi_status napi_get_instance_data(napi_env env, uint64_t key, void** data) {
  auto it = env->ctx->instance_data_registry.find(key);
  if (it == env->ctx->instance_data_registry.end()) {
    *data = nullptr;
  } else {
    qjsimpl::RefBase* idata = static_cast<qjsimpl::RefBase*>(it->second);

    *data = idata->Data();
  }

  return napi_clear_last_error(env);
}

void napi_attach_quickjs(napi_env env, LEPUSContext* context) {
#define SET_METHOD(API) env->napi_##API = &napi_##API;

  FOR_EACH_NAPI_ENGINE_CALL(SET_METHOD)

#undef SET_METHOD

  env->ctx = new napi_context__qjs(env, context);
}

void napi_detach_quickjs(napi_env env) {
  delete env->ctx;
  env->ctx = nullptr;
}

LEPUSContext* napi_get_env_context_quickjs(napi_env env) {
  return env->ctx->ctx;
}

LEPUSValue napi_js_value_to_quickjs_value(napi_env env, napi_value value) {
  return LEPUS_DupValue(env->ctx->ctx, ToJSValue(value));
}

napi_value napi_quickjs_value_to_js_value(napi_env env, LEPUSValue value) {
  return env->ctx->CreateHandle(value);
}
