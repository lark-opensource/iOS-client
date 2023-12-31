/*
 * luohengfeng@bytedance.com
 * 2020.2.3
 */

#ifndef _DETECTION_PROCESS_H_
#define _DETECTION_PROCESS_H_

#include "LensProcessBase.h"

using namespace LENS::FRAMEWORK;

namespace LENS {

namespace ALGORITHM {

    class LumaDetectionProcess: public LensProcessBase{
    public:
        LumaDetectionProcess();
        virtual ~LumaDetectionProcess();
    };

} /* namespace ALGORITHM */

} /* namespace LENS */

#endif //_ONEKEY_DETECTION_PROCESS_H_
