//
// Created by bytedance on 2020/8/20.
//

#ifndef HERMAS_TIME_UTIL_H
#define HERMAS_TIME_UTIL_H

#include <cstdint>

namespace hermas
{
    //精确到ms
    int64_t CurTimeMillis();

    // 精确到s
    int64_t CurTimeSecond();
    
    // 获取10min前时间戳
    int64_t TenMinutesAgoMillis();
}

#endif //HERMAS_TIME_UTIL_H
