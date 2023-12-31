#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_HOST_FUNCTION_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_HOST_FUNCTION_H_

#include <memory>
#include <unordered_map>

#include "base/observer/observer.h"
#include "jsbridge/quickjs/quickjs_helper.h"

namespace lynx {
namespace piper {
class QuickjsRuntime;
namespace detail {
piper::HostFunctionType& getHostFunction(QuickjsRuntime* rt,
                                         const piper::Function& obj);

class QuickjsHostFunctionProxy : public base::Observer {
  friend class QuickjsRuntimeInstance;

 public:
  QuickjsHostFunctionProxy(piper::HostFunctionType hostFunction,
                           QuickjsRuntime* rt);
  ~QuickjsHostFunctionProxy();
  void Update() override;
  piper::HostFunctionType& getHostFunction() { return hostFunction_; }
  static LEPUSValue createFunctionFromHostFunction(
      QuickjsRuntime* rt, LEPUSContext* ctx, const piper::PropNameID& name,
      unsigned int paramCount, piper::HostFunctionType func);

  static LEPUSValue FunctionCallback(LEPUSContext* ctx,
                                     LEPUSValueConst func_obj,
                                     LEPUSValueConst this_obj, int argc,
                                     LEPUSValueConst* argv, int flags);

  static void hostFinalizer(LEPUSRuntime* rt, LEPUSValue val);

 protected:
  QuickjsRuntime* rt_;
  piper::HostFunctionType hostFunction_;
  std::shared_ptr<bool> is_runtime_destroyed_;
};

}  // namespace detail

}  // namespace piper

}  // namespace lynx

// #ifdef __cplusplus
// }
// #endif
#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_HOST_FUNCTION_H_
