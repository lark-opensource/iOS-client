#ifndef _PRIVATE_UTILS_PREDICTOR_BASE_H_
#define _PRIVATE_UTILS_PREDICTOR_BASE_H_

#include "internal_smash.h"

SMASH_NAMESPACE_OPEN
NAMESPACE_OPEN(private_utils)
NAMESPACE_OPEN(predict)

struct ModelOutput {
  void* data;
  int n;
  int h;
  int w;
  int c;
  int type, fl;

  explicit ModelOutput() {}

  explicit ModelOutput(void* data, int n, int h, int w, int c, int type, int fl)
      : data(data), n(n), h(h), w(w), c(c), type(type), fl(fl) {}

  int Count() { return n * h * w * c; }
};

NAMESPACE_CLOSE(predict)
NAMESPACE_CLOSE(private_utils)
SMASH_NAMESPACE_CLOSE

#endif  // _PRIVATE_UTILS_PREDICTOR_BASE_H_
