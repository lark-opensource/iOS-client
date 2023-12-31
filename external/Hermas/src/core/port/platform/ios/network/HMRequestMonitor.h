//
//  HMRequestMonitor.h
//  Hermas
//
//  Created by 崔晓兵 on 7/1/2022.
//

#pragma once

#include <memory>
#include <future>

NS_ASSUME_NONNULL_BEGIN

namespace hermas {

struct HMRequestMonitor  {
public:
    HMRequestMonitor() : response_(std::make_shared<ResponseStruct>()) {
    }
    ~HMRequestMonitor() {
    }
    bool WaitForDone() { return is_done_.get(); }
    
    void SignalDone(bool success) { done_with_success_.set_value(success); }
    
    std::shared_ptr<ResponseStruct>& GetResponse() { return response_; }
private:
    std::promise<bool> done_with_success_;
    std::future<bool> is_done_ = done_with_success_.get_future();
    std::shared_ptr<ResponseStruct> response_;
};

}


NS_ASSUME_NONNULL_END
