#pragma once

#include <list>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>
#include <functional>
#include <memory>
#include <cassert>

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif  // __cplusplus

#define NAPI_COMPILE_UNIT qjs

#include "js_native_api.h"
#include "js_native_api_types.h"
#include "napi_state.h"

inline napi_value ToNapi(LEPUSValueConst* v) {
  return reinterpret_cast<napi_value>(v);
}

inline LEPUSValueConst ToJSValue(napi_value v) {
  return *reinterpret_cast<LEPUSValueConst*>(v);
}

namespace qjsimpl {
class HandleScope {
 public:
  explicit HandleScope(napi_env env);

  ~HandleScope();

  HandleScope(const HandleScope&) = delete;
  void operator=(const HandleScope&) = delete;

  napi_value Escape(napi_value v);

 private:
  struct Handle {
    LEPUSValue value;
    Handle* prev;
  };

  napi_value CreateHandle(LEPUSValue v) {
    Handle* h = new Handle{.value = v, .prev = handle_tail_};
    handle_tail_ = h;
    return ToNapi(&(h->value));
  }

  napi_env env_;
  HandleScope* prev_;
  Handle* handle_tail_;

  friend napi_context__qjs;
};

class Atom {
 public:
  Atom() : _ctx(nullptr), _atom(0) {}
  Atom(LEPUSContext* ctx, LEPUSValueConst value)
      : _ctx(ctx), _atom(LEPUS_ValueToAtom(ctx, value)) {}
  Atom(LEPUSContext* ctx, LEPUSAtom atom) : _ctx(ctx), _atom(atom) {}
  Atom(LEPUSContext* ctx, const char* str, size_t length = NAPI_AUTO_LENGTH)
      : _ctx(ctx),
        _atom(length == NAPI_AUTO_LENGTH ? LEPUS_NewAtom(ctx, str)
                                         : LEPUS_NewAtomLen(ctx, str, length)) {
  }

  Atom(Atom& other)
      : _ctx(other._ctx), _atom(LEPUS_DupAtom(_ctx, other._atom)) {}

  Atom(Atom&& other) : _ctx(other._ctx), _atom(other._atom) {
    other._ctx = nullptr;
    other._atom = 0;
  }

  ~Atom() {
    if (_atom) {
      LEPUS_FreeAtom(_ctx, _atom);
    }
  }

  bool IsValid() { return _atom > 0; }

  operator LEPUSAtom() const { return _atom; }

 private:
  LEPUSContext* _ctx;
  LEPUSAtom _atom;
};

class Value {
 public:
  Value() : _ctx(nullptr), _val() {}
  Value(LEPUSContext* ctx, LEPUSValue val) : _ctx(ctx), _val(val) {}

  ~Value() {
    if (_ctx) {
      LEPUS_FreeValue(_ctx, _val);
    }
  }

  operator LEPUSValueConst() { return _val; }

  LEPUSValue dup() { return LEPUS_DupValue(_ctx, _val); }

  LEPUSValue move() {
    _ctx = nullptr;
    return _val;
  }

 private:
  LEPUSContext* _ctx;
  LEPUSValue _val;
};

class Persistent;
class NativeInfo;

struct WeakInfo {
  std::list<Persistent*>::const_iterator weak_iter;
  std::function<void(void*)> cb;
  void* cb_arg;
};

class Persistent {
 public:
  Persistent() : _env(nullptr), _empty(true), _native_info(nullptr) {}

  Persistent(napi_env env, LEPUSValueConst value, NativeInfo* native_info);

  Persistent(const Persistent&) = delete;
  void operator=(const Persistent&) = delete;

  void Reset();
  void Reset(napi_env env, LEPUSValueConst value, NativeInfo* native_info);

  void SetWeak(void* data, std::function<void(void*)> cb);

  void ClearWeak();

  ~Persistent() { Reset(); }

  LEPUSValue Value();

  bool IsEmpty() { return _empty; }

  // called only in weak mode
  static void OnFinalize(Persistent* ref) {
    auto cb = ref->_weak_info->cb;
    auto cb_arg = ref->_weak_info->cb_arg;
    ref->Reset();
    cb(cb_arg);
  }

 private:
  NativeInfo* _get_native_info();

  napi_env _env;
  bool _empty;
  LEPUSValue _value;
  NativeInfo* _native_info;
  std::unique_ptr<WeakInfo> _weak_info;
};

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

}  // namespace qjsimpl

struct napi_context__qjs {
  napi_env env;
  LEPUSRuntime* rt{};
  LEPUSContext* ctx{};

  LEPUSValue V_NULL{LEPUS_NULL};
  LEPUSValue V_UNDEFINED{LEPUS_UNDEFINED};

  napi_context__qjs(napi_env env, LEPUSContext* ctx)
      : env(env),
        rt{LEPUS_GetRuntime(ctx)},
        ctx{ctx},
        PROP_NAME(ctx, "name"),
        PROP_LENGTH(ctx, "length"),
        PROP_PROTOTYPE(ctx, "prototype"),
        PROP_CONSTRUCTOR(ctx, "constructor"),
        PROP_FINALIZER(ctx, "@#fin@#"),
        PROP_MESSAGE(ctx, "message"),
        PROP_CODE(ctx, "code"),
        PROP_BUFFER(ctx, "buffer"),
        PROP_BYTELENGTH(ctx, "byteLength"),
        PROP_BYTEOFFSET(ctx, "byteOffset"),
        PROP_CTOR_MAGIC(ctx, "@#ctor@#") {
    env->ctx = this;
    handle_scope = new qjsimpl::HandleScope(env);
    // TODO lynx quickjs 未暴露 DupContext
  }

  ~napi_context__qjs() {
    qjsimpl::RefTracker::FinalizeAll(&finalizing_reflist);
    qjsimpl::RefTracker::FinalizeAll(&reflist);

    // root handle scope may be used during FinalizeAll
    // must delete at last
    delete handle_scope;
  }

  inline void Ref() { refs++; }
  inline void Unref() {
    if (--refs == 0) delete this;
  }

  template <typename T, typename U = std::function<void(napi_env, LEPUSValue)>>
  inline void CallIntoModule(T&& call, U&& handle_exception) {
    int open_handle_scopes_before = open_handle_scopes;
    (void)open_handle_scopes_before;
    napi_clear_last_error(this->env);
    call(this->env);
    assert(open_handle_scopes == open_handle_scopes_before);
    if (last_exception) {
      handle_exception(this->env, *last_exception);
      last_exception.reset();
    }
  }

  void CallFinalizer(napi_finalize cb, void* data, void* hint) {
    cb(this->env, data, hint);
  }

  qjsimpl::RefTracker::RefList reflist;
  qjsimpl::RefTracker::RefList finalizing_reflist;

  std::unique_ptr<LEPUSValue> last_exception;

  std::unordered_map<uint64_t, void*> instance_data_registry;

  int open_handle_scopes = 0;

  const qjsimpl::Atom PROP_NAME;
  const qjsimpl::Atom PROP_LENGTH;
  const qjsimpl::Atom PROP_PROTOTYPE;
  const qjsimpl::Atom PROP_CONSTRUCTOR;
  const qjsimpl::Atom PROP_FINALIZER;
  const qjsimpl::Atom PROP_MESSAGE;
  const qjsimpl::Atom PROP_CODE;
  const qjsimpl::Atom PROP_BUFFER;
  const qjsimpl::Atom PROP_BYTELENGTH;
  const qjsimpl::Atom PROP_BYTEOFFSET;
  const qjsimpl::Atom PROP_CTOR_MAGIC;

  napi_value CreateHandle(LEPUSValue v) {
    return handle_scope->CreateHandle(v);
  }

 private:
  int refs = 1;
  qjsimpl::HandleScope* handle_scope{};

  friend class qjsimpl::HandleScope;
};

struct napi_class__qjs {
  napi_class__qjs(LEPUSContext* ctx, LEPUSValue proto, LEPUSValue constructor)
      : ctx(ctx), proto(proto), constructor(constructor) {}

  ~napi_class__qjs() {
    LEPUS_FreeValue(ctx, proto);
    LEPUS_FreeValue(ctx, constructor);
  }

  LEPUSValue GetFunction() { return LEPUS_DupValue(ctx, constructor); }

  LEPUSContext* ctx;

  LEPUSValue proto;
  LEPUSValue constructor;
};

#define RETURN_STATUS_IF_FALSE(env, condition, status) \
  do {                                                 \
    if (!(condition)) {                                \
      return napi_set_last_error((env), (status));     \
    }                                                  \
  } while (0)

#define CHECK_ARG(env, arg) \
  RETURN_STATUS_IF_FALSE((env), ((arg) != nullptr), napi_invalid_arg)

#define CHECK_QJS(env, condition)                                        \
  do {                                                                   \
    if (!(condition)) {                                                  \
      return napi_set_exception(env, LEPUS_GetException(env->ctx->ctx)); \
    }                                                                    \
  } while (0)

// This does not call napi_set_last_error because the expression
// is assumed to be a NAPI function call that already did.
#define CHECK_NAPI(expr)                  \
  do {                                    \
    napi_status status = (expr);          \
    if (status != napi_ok) return status; \
  } while (0)

namespace qjsimpl {
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

inline HandleScope::HandleScope(napi_env env)
    : env_(env), prev_(env_->ctx->handle_scope), handle_tail_(nullptr) {
  env_->ctx->handle_scope = this;
}

inline HandleScope::~HandleScope() {
  Handle* curr = handle_tail_;
  while (curr) {
    Handle* temp = curr;
    LEPUS_FreeValue(env_->ctx->ctx, curr->value);
    curr = curr->prev;
    delete temp;
  }
  env_->ctx->handle_scope = prev_;
}

inline napi_value HandleScope::Escape(napi_value v) {
  return prev_->CreateHandle(LEPUS_DupValue(env_->ctx->ctx, ToJSValue(v)));
}
}  // namespace qjsimpl
