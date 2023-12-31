//
//  thread_cpu_usage.hpp
//  ByteView
//
//  Created by liujianlong on 2021/7/5.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

#ifndef thread_cpu_usage_hpp
#define thread_cpu_usage_hpp

#include <string>
#include <vector>
#include "thread_biz_scope.h"

namespace byteview {

struct ThreadCPUUsage {
    std::string thread_name;
    std::string queue_name;
    ByteViewThreadBizScope biz_scope = ByteViewThreadBizScope_Unknown;
    int index = -1;
    uint64_t thread_id = 0;
    float cpu_usage = -1.0f;
    static std::tuple<std::vector<ThreadCPUUsage>, float, float> GetThreadUsages(int topN);
    static float GetAppCPU();
};

}

#endif /* thread_cpu_usage_hpp */
