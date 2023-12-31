#ifndef VMSDK_QUICKJS_TOOLS_BYTECODECOMPILER_H
#define VMSDK_QUICKJS_TOOLS_BYTECODECOMPILER_H

#include <iostream>
#include <string>

#include "base_export.h"
#include "quickjs/tools/context.h"
#include "quickjs/tools/status.h"

namespace quickjs {
namespace bytecode {

class Value;
class BytecodeContext : public Context,
                        public std::enable_shared_from_this<BytecodeContext> {
 public:
  BytecodeContext(const std::string &jsStr = "", const BCRWConfig &conf = {})
      : Context(conf), jsStr(jsStr), complete(false) {}

  QJS_EXPORT Status compile();
  bool finished() const { return complete; }
  std::string getExceptionMessage();

  // -------------  extract -----------------
  static Status extractBinary(const std::string &bin, BCFmt &fmt) {
    DataBuffer DB(bin);
    DataExtract DE(DB);
    return fmt.read(DE);
  }

  // -------------  call & execute -----------------
  Status executeBinary(const std::string &bytecode) {
    Status status = Status::OK();
    LEPUSValue ret = LEPUS_EvalBinary(
        getContext(), reinterpret_cast<const uint8_t *>(bytecode.c_str()),
        bytecode.size(), 0);
    if (LEPUS_IsException(ret)) {
      std::string errMsg = getExceptionMessage();
      status = Status(ERR_FAILED_TO_EXECUTE_BINARY, errMsg);
    }
    LEPUS_FreeValue(getContext(), ret);
    return status;
  }

  QJS_EXPORT Status internalCall(LEPUSValue caller,
                                 const std::vector<LEPUSValue> &args,
                                 LEPUSValue &result) noexcept;
  QJS_EXPORT Status getAndCall(const std::string &name,
                               const std::vector<LEPUSValue> &args,
                               LEPUSValue &result) noexcept;
  QJS_EXPORT Status call(const std::string &name,
                         const std::vector<Value> &args, Value &result);

 private:
  QJS_EXPORT LEPUSValue getProprety(const std::string &name,
                                    LEPUSValue thisObj);
  std::shared_ptr<BytecodeContext> sharedFromThis() {
    return shared_from_this();
  }

 private:
  const std::string &jsStr;
  bool complete;
};

}  // namespace bytecode
}  // namespace quickjs

#endif
