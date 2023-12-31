#ifndef LYNX_JSBRIDGE_BINDINGS_TEST_TEST_CONTEXT_H_
#define LYNX_JSBRIDGE_BINDINGS_TEST_TEST_CONTEXT_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace test {

class TestContext : public piper::ImplBase {
 public:
  TestContext() = default;
  uint32_t TestPlusOne(uint32_t num) { return num + 1; }
};

}  // namespace test
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_BINDINGS_TEST_TEST_CONTEXT_H_
