// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_LEPUS_JSVALUE_HELPER_H_
#define LYNX_LEPUS_JSVALUE_HELPER_H_
#include <ostream>
#include <string>

#include "config/config.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

#include <functional>

#include "lepus/array.h"
#include "lepus/table.h"
#include "lepus/value.h"

#define ENABLE_PRINT_VALUE 1

namespace lynx {
namespace lepus {
class Value;

class LEPUSValueHelper {
 public:
  static constexpr int64_t MAX_SAFE_INTEGER = 9007199254740991;

  static inline LEPUSValue CreateLepusRef(LEPUSContext* ctx,
                                          base::RefCountedThreadSafeStorage* p,
                                          int32_t tag) {
    if (!p) return LEPUS_UNDEFINED;
    p->AddRef();
    return LEPUS_NewLepusWrap(ctx, p, tag);
  }

  static LEPUSValue ToJsValue(LEPUSContext* ctx, const lepus::Value& val,
                              bool deep_convert = false);

  static std::string LepusRefToStdString(LEPUSContext* ctx,
                                         const LEPUSValue& val);

  static std::string ToStdString(LEPUSContext* ctx, const LEPUSValue& val);

  static lepus::Value LepusRefToLepusValue(LEPUSContext* ctx,
                                           const LEPUSValue& val) {
    lepus::Value ret;
    switch (LEPUS_GetLepusRefTag(val)) {
      case Value_Array:
        ret.SetArray(GetLepusArray(val));
        break;
      case Value_Table:
        ret.SetTable(GetLepusTable(val));
        break;
      case Value_JSObject:
        ret.SetJSObject(GetLepusJSObject(val));
        break;
      case Value_ByteArray:
        ret.SetByteArray(GetLepusByteArray(val));
        break;
      default: {
        LOGE("Lepusref to LepusValue: unknow type " << GetType(ctx, val));
        assert(false);
        break;
      }
    }
    return ret;
  }

  /* The function is used for :
    1. convert jsvalue to lepus::Value when flag == 0;
    2. deep clone jsvalue to lepus::Value when flag == 1;
    3. shallow copy jsvalue to lepus::Value when flag == 2;
  flag default's value is 0
  */
  static lepus::Value ToLepusValue(LEPUSContext* ctx, const LEPUSValue& val,
                                   int32_t copy_flag = 0);

  static inline void IteratorJsValue(LEPUSContext* ctx, const LEPUSValue& val,
                                     JSValueIteratorCallback* pfunc) {
    if (!IsJsObject(val)) return;
    LEPUS_IterateObject(ctx, val, IteratorCallback,
                        reinterpret_cast<void*>(pfunc), nullptr);
  }

  static inline lepus::Value DeepCopyJsValue(LEPUSContext* ctx,
                                             const LEPUSValue& src,
                                             bool copy_as_jsvalue) {
    if (copy_as_jsvalue) {
      Value ret(ctx, LEPUS_DeepCopy(ctx, src));
      return ret;
    }
    return ToLepusValue(ctx, src, 1);
  }

  static LEPUSValue ShallowToJSValue(LEPUSContext* ctx,
                                     const lepus::Value& val);

  static inline LEPUSValue NewInt32(LEPUSContext* ctx, int32_t val) {
    return LEPUS_NewInt32(ctx, val);
  }

  static inline LEPUSValue NewUint32(LEPUSContext* ctx, uint32_t val) {
    return LEPUS_NewInt64(ctx, val);  // may to be float/int32
  }

  static inline LEPUSValue NewInt64(LEPUSContext* ctx, int64_t val) {
    if (val < MAX_SAFE_INTEGER && val > -MAX_SAFE_INTEGER) {
      return LEPUS_NewInt64(ctx, val);
    } else {
      return LEPUS_NewBigUint64(ctx, static_cast<uint64_t>(val));  //
    }
  }

  static inline LEPUSValue NewUint64(LEPUSContext* ctx, uint64_t val) {
    if (val < MAX_SAFE_INTEGER) {
      return LEPUS_NewInt64(ctx, val);
    } else {
      return LEPUS_NewBigUint64(ctx, val);
    }
  }

  static inline LEPUSValue NewPointer(void* p) {
    return LEPUS_MKPTR(LEPUS_TAG_LEPUS_CPOINTER, p);
  }

  static inline LEPUSValue NewString(LEPUSContext* ctx, const char* name) {
    return LEPUS_NewString(ctx, name);
  }

  static inline int32_t GetLength(LEPUSContext* ctx, const LEPUSValue& val) {
    return LEPUS_GetLength(ctx, val);
  }

  static inline bool IsLepusRef(const LEPUSValue& val) {
    return LEPUS_IsLepusRef(val);
  }
  static inline bool IsLepusJSObject(const LEPUSValue& val) {
    return LEPUS_GetLepusRefTag(val) == Value_JSObject;
  }

  static inline bool IsLepusArray(const LEPUSValue& val) {
    return LEPUS_GetLepusRefTag(val) == Value_Array;
  }

  static inline bool IsLepusTable(const LEPUSValue& val) {
    return LEPUS_GetLepusRefTag(val) == Value_Table;
  }

  static inline bool IsLepusByteArray(const LEPUSValue& val) {
    return LEPUS_GetLepusRefTag(val) == Value_ByteArray;
  }

  static inline bool IsJSCpointer(const LEPUSValue& val) {
    return LEPUS_VALUE_GET_TAG(val) == LEPUS_TAG_LEPUS_CPOINTER;
  }

  static inline void* JSCpointer(const LEPUSValue& val) {
    return LEPUS_VALUE_GET_PTR(val);
  }

  static inline LEPUSObject* GetLepusJSObject(const LEPUSValue& val) {
    return reinterpret_cast<LEPUSObject*>(LEPUS_GetLepusRefPoint(val));
  }

  static inline ByteArray* GetLepusByteArray(const LEPUSValue& val) {
    return reinterpret_cast<ByteArray*>(LEPUS_GetLepusRefPoint(val));
  }

  static inline Dictionary* GetLepusTable(const LEPUSValue& val) {
    return reinterpret_cast<Dictionary*>(LEPUS_GetLepusRefPoint(val));
  }
  static inline CArray* GetLepusArray(const LEPUSValue& val) {
    return reinterpret_cast<CArray*>(LEPUS_GetLepusRefPoint(val));
  }

  static inline bool IsJsObject(const LEPUSValue& val) {
    return LEPUS_IsObject(val);
  }

  static inline bool IsObject(const LEPUSValue& val) {
    return LEPUS_IsObject(val) || (IsLepusTable(val));
  }

  static inline bool IsJsArray(LEPUSContext* ctx, const LEPUSValue& val) {
    return LEPUS_IsArray(ctx, val);
  }

  static inline bool IsArray(LEPUSContext* ctx, const LEPUSValue& val) {
    return LEPUS_IsArray(ctx, val) || (IsLepusArray(val));
  }

  static inline bool IsJSString(const LEPUSValue& val) {
    return LEPUS_IsString(val);
  }

  static inline bool IsUndefined(const LEPUSValue& val) {
    return LEPUS_IsUndefined(val);
  }

  static inline bool IsJsFunction(LEPUSContext* ctx, const LEPUSValue& val) {
    return LEPUS_IsFunction(ctx, val);
  }

  static inline bool SetProperty(LEPUSContext* ctx, LEPUSValue obj,
                                 uint32_t idx, const LEPUSValue& prop) {
    return !!LEPUS_SetPropertyUint32(ctx, obj, idx, prop);
  }

  static inline bool SetProperty(LEPUSContext* ctx, LEPUSValue obj,
                                 const char* name, const LEPUSValue& prop) {
    return !!LEPUS_SetPropertyStr(ctx, obj, name, prop);
  }

  static inline bool SetProperty(LEPUSContext* ctx, LEPUSValue obj,
                                 uint32_t idx, const lepus::Value& prop) {
    return !!LEPUS_SetPropertyUint32(ctx, obj, idx, prop.ToJSValue(ctx));
  }

  static inline bool SetProperty(LEPUSContext* ctx, LEPUSValue obj,
                                 const lepus::String& key,
                                 const lepus::Value& val) {
    return !!LEPUS_SetPropertyStr(ctx, obj, key.c_str(), val.ToJSValue(ctx));
  }

  static inline LEPUSValue GetPropertyJsValue(LEPUSContext* ctx,
                                              const LEPUSValue& obj,
                                              const char* name) {
    return LEPUS_GetPropertyStr(ctx, obj, name);
  }

  static inline LEPUSValue GetPropertyJsValue(LEPUSContext* ctx,
                                              const LEPUSValue& obj,
                                              uint32_t idx) {
    return LEPUS_GetPropertyUint32(ctx, obj, idx);
  }

  static inline bool HasProperty(LEPUSContext* ctx, const LEPUSValue& obj,
                                 const lepus::String& key) {
    LEPUSAtom atom = LEPUS_NewAtom(ctx, key.c_str());
    int32_t ret = LEPUS_HasProperty(ctx, obj, atom);
    LEPUS_FreeAtom(ctx, atom);
    return !!ret;
  }

  static inline bool IsLepusEqualJsValue(LEPUSContext* ctx,
                                         const lepus::Value& src,
                                         const LEPUSValue& dst) {
    if (IsArray(ctx, dst)) {  // dst is arrary
      if (!src.IsArray()) return false;
      return IsLepusEqualJsArray(ctx, src.Array().Get(), dst);
    } else if (IsObject(dst)) {  // dst is object. including js object and lepus
                                 // table ref
      if (!src.IsTable()) return false;
      return IsLepusEqualJsObject(ctx, src.Table().Get(), dst);
    } else if (IsJsFunction(ctx, dst)) {
      return false;
    }
    // the last need to be translated to lepus::Value for doing equal,
    // and the dst is not array or object, so the convert is light
    return src == ToLepusValue(ctx, dst);
  }

  static bool IsJsValueEqualJsValue(LEPUSContext* ctx, const LEPUSValue& left,
                                    const LEPUSValue& right);

  static void PrintValue(std::ostream& s, LEPUSContext* ctx,
                         const LEPUSValue& val, uint32_t prefix = 1);
  static void Print(LEPUSContext* ctx, const LEPUSValue& val);
  static const char* GetType(LEPUSContext* ctx, const LEPUSValue& val);

 private:
  static inline void IteratorCallback(LEPUSContext* ctx, LEPUSValue key,
                                      LEPUSValue value, void* pfunc,
                                      void* raw_data) {
    reinterpret_cast<JSValueIteratorCallback*>(pfunc)->operator()(ctx, key,
                                                                  value);
  }

  static bool IsLepusEqualJsArray(LEPUSContext* ctx, lepus::CArray* src,
                                  const LEPUSValue& dst);

  static bool IsLepusEqualJsObject(LEPUSContext* ctx, lepus::Dictionary* src,
                                   const LEPUSValue& dst);

  static lepus::Value ToLepusArray(LEPUSContext* ctx, const LEPUSValue& val,
                                   int32_t flag = 0);

  static lepus::Value ToLepusTable(LEPUSContext* ctx, const LEPUSValue& val,
                                   int32_t flag = 0);

  static LEPUSValue TableToJsValue(LEPUSContext* ctx, const lepus::Value& val,
                                   bool deep_convert);

  static LEPUSValue ArrayToJsValue(LEPUSContext* ctx, const lepus::Value& val,
                                   bool deep_convert);
};

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_JSVALUE_HELPER_H_
