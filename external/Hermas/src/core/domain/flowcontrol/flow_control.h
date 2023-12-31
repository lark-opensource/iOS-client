//
//  flow_control.h
//  Hermas
//
//  Created by 崔晓兵 on 18/2/2022.
//

#ifndef flow_control_h
#define flow_control_h

#include "env.h"

namespace hermas {

enum FlowControlStrategyType {
    FlowControlStrategyTypeNormal = 0,
    FlowControlStrategyTypeLimited
};

// CRTP

template <class Derived>
class BaseFlowControlStrategy  {
public:
    long GetUploadMaxSize()  {
        return static_cast<Derived*>(this)->InternalGetUploadMaxSize();
    }
    long GetUploadInterval() {
        return static_cast<Derived*>(this)->InternalGetUploadInterval();
    }
};


class NormalFlowControlStrategy : public BaseFlowControlStrategy<NormalFlowControlStrategy> {
private:
    friend class BaseFlowControlStrategy<NormalFlowControlStrategy>;
    long InternalGetUploadMaxSize();
    long InternalGetUploadInterval();
    
};

class LimitedFlowControlStrategy : public BaseFlowControlStrategy<LimitedFlowControlStrategy> {
private:
    friend class BaseFlowControlStrategy<LimitedFlowControlStrategy>;
    long InternalGetUploadMaxSize();
    long InternalGetUploadInterval();
};


template <class T>
long GetUploadMaxSize(BaseFlowControlStrategy<T>&& strategy) {
    return strategy.GetUploadMaxSize();
}

template <class T>
long GetUploadInterval(BaseFlowControlStrategy<T>&& strategy) {
    return strategy.GetUploadInterval();
}

}

#endif /* flow_control_hpp */
