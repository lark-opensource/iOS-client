//
// Created by Longtao Zhang on 2021/6/19.
//

#ifndef LENS_SmartCodecFLOWGRAPH_H
#define LENS_SmartCodecFLOWGRAPH_H
#include "LensFlowGraphBase.h"

using namespace LENS::FRAMEWORK;

namespace LENS {

    namespace ALGORITHM {

        class SmartCodecFlowGraph:public LensFlowGraphBase{
        public:
            SmartCodecFlowGraph();
            virtual ~SmartCodecFlowGraph();
        };

    } /* namespace ALGORITHM */

} /* namespace LENS */
#endif //LENS_SmartCodecFLOWGRAPH_H

