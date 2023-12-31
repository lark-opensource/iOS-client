//  Created by wangheyang on 2020/5/19.

#ifndef LYNX_JSBRIDGE_BINDINGS_BIG_INT_JSBI_H_
#define LYNX_JSBRIDGE_BINDINGS_BIG_INT_JSBI_H_

#include <string>
#include <vector>

#include "jsbridge/bindings/big_int/big_integer.h"
#include "jsbridge/bindings/big_int/constants.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
class Runtime;
// 定义JSBI对象，用于抽象对BigInt的操作
class JSBI : public HostObject {
 public:
  virtual Value get(Runtime*, const PropNameID& name) override;
  virtual std::vector<PropNameID> getPropertyNames(Runtime& rt) override;

 private:
  std::optional<piper::Value> BigInt(Runtime* rt, const Value* args,
                                     size_t count,
                                     const std::string& func_name);

  std::optional<piper::Value> operate(Runtime* rt, const Value* args,
                                      size_t count,
                                      const std::string& func_name);
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_BINDINGS_BIG_INT_JSBI_H_
