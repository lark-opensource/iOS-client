#pragma once

#include <JavaScriptCore/JavaScript.h>

#include <list>
#include <unordered_map>
#include <vector>

#define NAPI_COMPILE_UNIT jsc

#include "js_native_api.h"
#include "js_native_api_types.h"
#include "napi_state.h"

namespace jscimpl {

class RefTracker {
 public:
  RefTracker() {}
  virtual ~RefTracker() {}
  virtual void Finalize(bool isEnvTeardown) {}

  typedef RefTracker RefList;

  inline void Link(RefList* list) {
    prev_ = list;
    next_ = list->next_;
    if (next_ != nullptr) {
      next_->prev_ = this;
    }
    list->next_ = this;
  }

  inline void Unlink() {
    if (prev_ != nullptr) {
      prev_->next_ = next_;
    }
    if (next_ != nullptr) {
      next_->prev_ = prev_;
    }
    prev_ = nullptr;
    next_ = nullptr;
  }

  static void FinalizeAll(RefList* list) {
    while (list->next_ != nullptr) {
      list->next_->Finalize(true);
    }
  }

 private:
  RefList* next_ = nullptr;
  RefList* prev_ = nullptr;
};

class Reference;
}  // end of namespace jscimpl

struct napi_context__jsc {
  napi_env env;
  JSGlobalContextRef context{};

  napi_context__jsc(napi_env env, JSGlobalContextRef context)
      : env(env), context{context} {
    JSGlobalContextRetain(context);

    static JSStringRef func = JSStringCreateWithUTF8CString("Function");
    JSValueRef exc = nullptr;
    JSObjectRef global = JSContextGetGlobalObject(context);
    JSValueRef value = JSObjectGetProperty(context, global, func, &exc);
    // If we don't have Function then something bad is going on.
    assert(exc == nullptr);
    JSObjectRef func_ctor = JSValueToObject(context, value, &exc);
    if (func_ctor) {
      func_proto = JSObjectGetPrototype(context, func_ctor);
      if (func_proto) {
        JSValueProtect(context, func_proto);
      }
    }
  }

  ~napi_context__jsc() {
    if (func_proto) {
      JSValueUnprotect(context, func_proto);
      func_proto = nullptr;
    }
    jscimpl::RefTracker::FinalizeAll(&finalizing_reflist);
    jscimpl::RefTracker::FinalizeAll(&reflist);
    JSGlobalContextRelease(context);
  }

  inline void Ref() { refs++; }
  inline void Unref() {
    if (--refs == 0) delete this;
  }

  template <typename T, typename U = std::function<void(napi_env, JSValueRef)>>
  inline void CallIntoModule(T&& call, U&& handle_exception) {
    napi_clear_last_error(this->env);
    call(this->env);
    if (last_exception) {
      handle_exception(this->env, last_exception);
      last_exception = nullptr;
    }
  }

  void CallFinalizer(napi_finalize cb, void* data, void* hint) {
    cb(this->env, data, hint);
  }

  jscimpl::RefTracker::RefList reflist;
  jscimpl::RefTracker::RefList finalizing_reflist;

  JSValueRef last_exception{};

  JSValueRef func_proto{};

  std::unordered_map<uint64_t, void*> instance_data_registry;

 private:
  int refs = 1;
};

struct napi_class__jsc {
  explicit napi_class__jsc(JSContextRef context, JSObjectRef proto,
                           JSObjectRef ctor)
      : _ctx(context), _proto(proto), _ctor(ctor) {
    JSValueProtect(context, _ctor);
    JSValueProtect(context, _proto);
  }

  ~napi_class__jsc() {
    JSValueUnprotect(_ctx, _proto);
    JSValueUnprotect(_ctx, _ctor);
  }

  JSContextRef _ctx;
  JSObjectRef _proto;
  JSObjectRef _ctor;
};

#define RETURN_STATUS_IF_FALSE(env, condition, status) \
  do {                                                 \
    if (!(condition)) {                                \
      return napi_set_last_error((env), (status));     \
    }                                                  \
  } while (0)

#define CHECK_ARG(env, arg) \
  RETURN_STATUS_IF_FALSE((env), ((arg) != nullptr), napi_invalid_arg)

#define CHECK_JSC(env, exception)                \
  do {                                           \
    if ((exception) != nullptr) {                \
      return napi_set_exception(env, exception); \
    }                                            \
  } while (0)

// This does not call napi_set_last_error because the expression
// is assumed to be a NAPI function call that already did.
#define CHECK_NAPI(expr)                  \
  do {                                    \
    napi_status status = (expr);          \
    if (status != napi_ok) return status; \
  } while (0)

namespace jscimpl {
// Adapter for napi_finalize callbacks.
class Finalizer {
 public:
  // Some Finalizers are run during shutdown when the napi_env is destroyed,
  // and some need to keep an explicit reference to the napi_env because they
  // are run independently.
  enum EnvReferenceMode { kNoEnvReference, kKeepEnvReference };

 protected:
  Finalizer(napi_env env, napi_finalize finalize_callback, void* finalize_data,
            void* finalize_hint, EnvReferenceMode refmode = kNoEnvReference)
      : _env(env),
        _finalize_callback(finalize_callback),
        _finalize_data(finalize_data),
        _finalize_hint(finalize_hint),
        _has_env_reference(refmode == kKeepEnvReference) {
    if (_has_env_reference) _env->ctx->Ref();
  }

  ~Finalizer() {
    if (_has_env_reference) _env->ctx->Unref();
  }

 public:
  static Finalizer* New(napi_env env, napi_finalize finalize_callback = nullptr,
                        void* finalize_data = nullptr,
                        void* finalize_hint = nullptr,
                        EnvReferenceMode refmode = kNoEnvReference) {
    return new Finalizer(env, finalize_callback, finalize_data, finalize_hint,
                         refmode);
  }

  static void Delete(Finalizer* finalizer) { delete finalizer; }

 protected:
  napi_env _env;
  napi_finalize _finalize_callback;
  void* _finalize_data;
  void* _finalize_hint;
  bool _finalize_ran = false;
  bool _has_env_reference = false;
};
}  // namespace jscimpl
