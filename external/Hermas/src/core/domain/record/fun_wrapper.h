//
// Created by bytedance on 2020/8/12.
//

#ifndef HERMAS_FUN_WRAPPER_H
#define HERMAS_FUN_WRAPPER_H
#include <memory>

namespace hermas {

struct IRecordRealCallback {
    virtual ~IRecordRealCallback() = default;
    virtual void Callback() = 0;
};

}

#endif //HERMAS_FUN_WRAPPER_H
