//
// Created by bytedance on 2020/6/10.
//

#ifndef NLEPLATFORM_MODEL_NLEERROR_H
#define NLEPLATFORM_MODEL_NLEERROR_H

#include <cstdint>
#include "nle_export.h"

namespace cut::model {
    enum NLE_EXPORT_CLASS class NLEError : int32_t {
        SUCCESS = 0,
        FAILED = -1,
        OPERATION_ILLEGAL = -2,
        NO_CHANGED = -3,
        OBJECTS_NOT_FOUND = -4,
        NOT_SUPPORT = -5,
        FILE_ACCESS_ERROR = -6,
        PARAM_INVALID = -7
    };
}

#endif //NLEPLATFORM_MODEL_NLEERROR_H
