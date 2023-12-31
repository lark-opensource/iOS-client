#ifndef FASTCV_ML_H
#define FASTCV_ML_H
#include "mat.h"
#include "types.hpp"

namespace FASTCV {
namespace ML{
    enum MLError {
        NO_ERROR = 0,
        LOAD_MODE_ERROR = -1,
        INVALID_HANDLE = -2,
        INVALID_DATA = -3,
        PREDICATION_ERROR = -4,
    };

    CV_EXPORTS void *CreateMLHandle(const char *mode_file);
    
    CV_EXPORTS MLError Predication(void *handle, EXPORTS::Mat &in_mat, EXPORTS::Mat &out_mat);

    CV_EXPORTS void DestroyMLHandle(void *handle);

    CV_EXPORTS bool IsFastCLModel(const char *mode_file);
}
}

#endif
