#ifndef FASTCV_OPEXT_H
#define FASTCV_OPEXT_H
#include <vector>
#include "mat.h"
#include "types.hpp"

#if defined(WIN32) || defined(_WIN64)
#include <iostream>
#elif __linux__
#include <string.h>
#include <memory>
#endif

#include <initializer_list>

namespace FASTCV {
namespace EXPORTS {
    /**
    * Support Custom OP. Only Support OpenCL and Metal.
    * @param opName Custom op name it must be same to the function of kernel.
    * @param kernel Kernel String.
    * @param pCtx Inited GPU Context. 
    */
    CV_EXPORTS FastCVCode buildOP(const std::string &opName, const std::string &kernel, const GPUContext *pCtx);

    /**
    * Support Custom OP. Only Support OpenCL and Metal.
    * @param opName Custom op name it must be same to the function of kernel.
    * @param inputs the vector of UMat for inputs.
    * @param outputs the vector of UMat for outputs. 
    * @param global_worksize_x the number of work items in x dimension
    * @param global_worksize_y the number of work items in y dimension
    * @param local_worksize_x the number of work_items in a work_group，in x dimension 
    * @param local_worksize_y the number of work_items in a work_group，in y dimension 
    * @param il  global_worksize_x, global_worksize_y, and KernelArgs.
    */
    CV_EXPORTS FastCVCode execOP(const std::string &opName, std::vector<UMat*> inputs, std::vector<UMat*> outputs, size_t global_worksize_x, size_t global_worksize_y, size_t local_worksize_x, size_t local_worksize_y, std::initializer_list<float> il);

}
} 

#endif
