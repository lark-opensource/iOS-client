//
// Created by bytedance on 2022/11/7.
//

#ifndef PRELOAD_VC_PRIORITY_TASK_INFO_H
#define PRELOAD_VC_PRIORITY_TASK_INFO_H

#include "vc_base.h"
#include "vc_info.h"
#include "vc_json.h"

#include <vector>

VC_NAMESPACE_BEGIN

class VCPriorityTaskInfo {
public:
    VCPriorityTaskInfo() = default;
    void pushRetryCode(int code);
    VCJson retryCodeJson();

    uint64_t add_timestamp_milli = 0;
    uint64_t first_execute_timestamp_milli = 0;
    uint64_t last_execute_timestamp_milli = 0;
    uint64_t finish_timestamp_milli = 0;
    int ret = 0;

private:
    std::mutex mMutex;
    std::vector<int> retry_codes;
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_PRIORITY_TASK_INFO_H
