//
// Created by Longtao Zhang on 2021/6/19.
//

#ifndef LENS_SmartCodecPROCESS_H
#define LENS_SmartCodecPROCESS_H

#include "LensProcessBase.h"

using namespace LENS::FRAMEWORK;

namespace LENS {
    namespace ALGORITHM {

        class SmartCodecProcess:public LensProcessBase{
        public:
            SmartCodecProcess();
            virtual ~SmartCodecProcess();
        };

    } /* namespace ALGORITHM */
} /* namespace LENS */

#endif //LENS_SmartCodecPROCESS_H
