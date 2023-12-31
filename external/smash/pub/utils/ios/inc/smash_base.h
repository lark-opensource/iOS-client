#ifndef _UTILS_SMASH_BASE_H_
#define _UTILS_SMASH_BASE_H_

#include <string>
#include "internal_smash.h"

SMASH_NAMESPACE_OPEN
NAMESPACE_OPEN(base)

#define SMASH_EPS (1e-6)

class Exception {
 public:
  explicit Exception();

  Exception(const std::string& err,
            const std::string& func,
            const std::string& file,
            int line);

  virtual ~Exception();

  const char* what();

  void Message();

 private:
  std::string err;
  std::string func;
  std::string file;
  int line;
  std::string msg;
};

void Error(const std::string& err,
           const char* func,
           const char* file,
           int line);

#define SMASH_Assert(expr, code)                             \
  if (!!(expr))                                              \
    ;                                                        \
  else {                                                     \
    return code;                                             \
  };

#define SMASH_Assert2(expr, code, msg)                     \
  if (!!(expr))                                            \
    ;                                                      \
  else {                                                   \
    return code;                                           \
  };

#define SMASH_AssertNoReturn(expr) \
  if (!!(expr))                    \
    ;                              \
  else                             \
    ;

#define SMASH_AssertNoReturn2(expr, msg) \
  if (!!(expr))                          \
    ;                                    \
  else                                   \
    ;

NAMESPACE_CLOSE(base)
SMASH_NAMESPACE_CLOSE

#endif  // _UTILS_SMASH_BASE_H_
