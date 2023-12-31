/*
 * luohengfeng@bytedance.com
 * 2020.2.3
 */

#ifndef _DETECTION_FLOW_GRAPH_H_
#define _DETECTION_FLOW_GRAPH_H_

#include "LensFlowGraphBase.h"

using namespace LENS::FRAMEWORK;

namespace LENS {

namespace ALGORITHM {

    class LumaDetectionFlowGraph: public LensFlowGraphBase{
    public:
        LumaDetectionFlowGraph();
        virtual ~LumaDetectionFlowGraph();
    };

} /* namespace ALGORITHM */

} /* namespace LENS */

#endif //_ONEKEY_DETECTION_FLOW_GRAPH_H_
