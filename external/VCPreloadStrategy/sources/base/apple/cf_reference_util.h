//
// Created by zhongzhendong on 2020/12/2.
//

#ifndef STRATEGYCENTER_CF_REFERENCE_UTIL_H
#define STRATEGYCENTER_CF_REFERENCE_UTIL_H

#include "vc_base.h"

VC_NAMESPACE_BEGIN

template <class T>
class CFRef {
public:
    CFRef(T instance) : instance_(instance) {}

    CFRef() : instance_(nullptr) {}

    ~CFRef() {
        if (instance_ != nullptr) {
            CFRelease(instance_);
        }

        instance_ = nullptr;
    }

    void Reset(T instance) {
        if (instance_ == instance) {
            return;
        }
        if (instance_ != nullptr) {
            CFRelease(instance_);
        }

        instance_ = instance;
    }

    operator T() const {
        return instance_;
    }

    operator bool() const {
        return instance_ != nullptr;
    }

private:
    T instance_;
    VC_DISALLOW_COPY_AND_ASSIGN(CFRef);
};

VC_NAMESPACE_END

#endif // STRATEGYCENTER_CF_REFERENCE_UTIL_H
