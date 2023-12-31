#ifndef VMSDK_QUICKJS_TOOLS_CONTEXT_H
#define VMSDK_QUICKJS_TOOLS_CONTEXT_H

#include <iostream>
#include <limits>

#include "quickjs/tools/bytecode_fmt.h"

extern "C" {
#include <stdlib.h>

#include "quickjs.h"
}

namespace quickjs {
namespace bytecode {

class Context {
 public:
  Context(const BCRWConfig &conf) : config(conf) {
    rt = LEPUS_NewRuntime();
#ifndef ENABLE_EM_FEATURE
    assert(rt && "rt should be not nullptr");
#endif
    ctx = LEPUS_NewContext(rt);
    LEPUS_SetMaxStackSize(ctx, std::numeric_limits<uint32_t>::max());
  }

  virtual ~Context() {
    LEPUS_FreeValue(ctx, topLevelFunc);
    LEPUS_FreeContext(ctx);
    LEPUS_FreeRuntime(rt);
  }

  Status init() {
    switch (config.shuffleMode) {
      case BC_SHUFFLE_MODE_NONE:
        break;
      case BC_SHUFFLE_MODE_XOR: {
        // 1. get move number
        if (config.shuffleArgs.empty())
          return Status(ERR_MISSING_KEY,
                        "should have value under BC_SHUFFLE_SIMPLE_MOVE");

        // 2. get move number
        uint32_t moveNumber = config.shuffleArgs.back();

        // 3. set callback and value to struct
        LEPUS_EnableXorTransform(ctx, moveNumber);
      } break;
      default:
        return Status(ERR_INVALID_SHUFFLE_MODE,
                      "can not handle this shuffle mode");
    }
    LEPUS_EnableSecurityFeature(ctx);
    return Status::OK();
  }

  void setTopLevelFunction(LEPUSValue val) {
    if (!LEPUS_IsUndefined(topLevelFunc))
      LEPUS_FreeValue(getContext(), topLevelFunc);
    topLevelFunc = val;
  }

  std::string serializeByteCode() {
    size_t outBufLen = 0;
    uint8_t *outBuf = LEPUS_WriteObject(
        getContext(), &outBufLen, getTopLevelFunc(), LEPUS_WRITE_OBJ_BYTECODE);
    std::string result(reinterpret_cast<const char *>(outBuf), outBufLen);
    lepus_free(getContext(), outBuf);
    return result;
  }

  // get & set
  LEPUSContext *getContext() const { return ctx; }
  LEPUSRuntime *getRuntime() const { return rt; }
  LEPUSValue getTopLevelFunc() const {
    return LEPUS_DupValue(ctx, topLevelFunc);
  }

 protected:
  BCRWConfig config;
  LEPUSContext *ctx;
  LEPUSRuntime *rt;
  LEPUSValue topLevelFunc;
};

}  // namespace bytecode
}  // namespace quickjs

#endif
