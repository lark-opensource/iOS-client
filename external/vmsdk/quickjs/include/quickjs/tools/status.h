#ifndef VMSDK_QUICKJS_TOOLS_STATUS_H
#define VMSDK_QUICKJS_TOOLS_STATUS_H

#include <string>

namespace quickjs {
namespace bytecode {

#define ERR_SUCCESS 0
#define ERR_EVAL_BINARY -1
#define ERR_FAILED_TO_COMPILE -2
#define ERR_FAILED_TO_CREATE_ATOM -3
#define ERR_CONVERET_UNDEF_OR_NULL_TO_NATIVE -4
#define ERR_GET_EXCEPTION_FOR_CALLING -5
#define ERR_OBJ_IS_NOT_FUNC -6
#define ERR_FAIL_CONVERT_TO_JSVALUE -7
#define ERR_FAIL_CONVERT_TO_NATIVE -8
#define ERR_FAIL_EXTRACT_BINARY -9
#define ERR_HEAPOVERFLOW -10
#define ERR_INVALID_SHUFFLE_MODE -11
#define ERR_MISSING_KEY -12
#define ERR_CAN_NOT_CONVERT_STRING_TO_INT -13
#define ERR_FAILED_TO_EXECUTE_BINARY -14
#define ERR_FAILED_TO_GET_CONF -15

class Status {
 public:
  Status(int err, const std::string &msg) : err(err), msg(msg) {}

  bool operator==(const Status &other) const {
    return err == other.err && msg == other.msg;
  }

  Status(const Status &other) { this->operator=(other); }
  Status &operator=(const Status &other) {
    err = other.err;
    msg = other.msg;
    return *this;
  }

  int errCode() const { return err; }
  std::string errMsg() const { return msg; }

  bool ok() const { return *this == Status::OK(); }
  static Status OK() {
    Status status(ERR_SUCCESS, "");
    return status;
  }

 private:
  int err;
  std::string msg;
};

#define RETURN_IF_HAS_ERROR(fn)      \
  {                                  \
    Status status = fn;              \
    if (!status.ok()) return status; \
  }

}  // namespace bytecode
}  // namespace quickjs

#endif
