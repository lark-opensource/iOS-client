//
//  flow_control.cpp
//  Hermas
//
//  Created by 崔晓兵 on 18/2/2022.
//

#include "flow_control.h"
#include "env.h"

namespace hermas {

long NormalFlowControlStrategy::InternalGetUploadMaxSize() {
    return GlobalEnv::GetInstance().GetMaxReportSize();
}

long NormalFlowControlStrategy::InternalGetUploadInterval() {
    return GlobalEnv::GetInstance().GetReportInterval();
}


long LimitedFlowControlStrategy::InternalGetUploadMaxSize() {
    return GlobalEnv::GetInstance().GetMaxReportSizeLimited() ?: GlobalEnv::GetInstance().GetMaxReportSize() * 0.5;
}

long LimitedFlowControlStrategy::InternalGetUploadInterval() {
    return GlobalEnv::GetInstance().GetReportIntervalLimited() ?: GlobalEnv::GetInstance().GetReportInterval() * 0.5;
}

}
