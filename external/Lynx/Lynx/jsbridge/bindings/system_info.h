//
// Created by shiwentao on 2019/10/28.
//

#ifndef LYNX_JSBRIDGE_BINDINGS_SYSTEM_INFO_H_
#define LYNX_JSBRIDGE_BINDINGS_SYSTEM_INFO_H_
#include <vector>

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
class Runtime;

class SystemInfo : public HostObject {
 public:
  virtual Value get(Runtime*, const PropNameID& name) override;
  virtual void set(Runtime*, const PropNameID& name,
                   const Value& value) override;
  virtual std::vector<PropNameID> getPropertyNames(Runtime& rt) override;
};
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_SYSTEM_INFO_H_
