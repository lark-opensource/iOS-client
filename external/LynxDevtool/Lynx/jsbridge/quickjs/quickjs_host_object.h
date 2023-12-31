#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_HOST_OBJECT_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_HOST_OBJECT_H_
#include <memory>
#include <string>
#include <unordered_map>

#include "base/observer/observer.h"
#include "jsbridge/quickjs/quickjs_helper.h"

namespace lynx {
namespace piper {
class QuickjsRuntime;
namespace detail {
// HostObject details
struct QuickjsHostObjectProxyBase : public base::Observer {
  QuickjsHostObjectProxyBase(QuickjsRuntime* rt,
                             const std::shared_ptr<piper::HostObject>& sho);
  virtual ~QuickjsHostObjectProxyBase();

  void Update() override;

 public:
  QuickjsRuntime* runtime;
  std::shared_ptr<piper::HostObject> hostObject;
  std::shared_ptr<bool> is_runtime_destroyed_;
  friend class piper::QuickjsRuntime;
};

struct QuickjsHostObjectProxy : public QuickjsHostObjectProxyBase {
 public:
  QuickjsHostObjectProxy(QuickjsRuntime* rt,
                         const std::shared_ptr<piper::HostObject>& sho)
      : QuickjsHostObjectProxyBase(rt, sho) {}

  static void hostFinalizer(LEPUSRuntime* rt, LEPUSValue val);
  static LEPUSValue getProperty(LEPUSContext* ctx, LEPUSValueConst obj,
                                LEPUSAtom atom, LEPUSValueConst receiver);

  static int getOwnProperty(LEPUSContext* ctx, LEPUSPropertyDescriptor* desc,
                            LEPUSValueConst obj, LEPUSAtom prop);

  static int setProperty(LEPUSContext* ctx, LEPUSValueConst obj, LEPUSAtom atom,
                         LEPUSValueConst value, LEPUSValueConst receiver,
                         int flags);

  static int getPropertyNames(LEPUSContext* ctx, LEPUSPropertyEnum** ptab,
                              uint32_t* plen, LEPUSValueConst obj);

  static piper::Object createObject(lynx::piper::QuickjsRuntime* ctx,
                                    std::shared_ptr<piper::HostObject> ho);

  friend class QuickJsRuntime;
};

}  // namespace detail

}  // namespace piper

}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_HOST_OBJECT_H_
