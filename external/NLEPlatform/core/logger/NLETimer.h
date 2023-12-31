//
// Created by wangchengyi.1 on 2021/5/11.
//

#ifndef NLECONSOLE_NLETIMER_H
#define NLECONSOLE_NLETIMER_H

#include <cstdint>
#include <chrono>
#include "nle_export.h"

namespace nle {
    class NLE_EXPORT_CLASS NLETimer {
    public:
        NLETimer();

        void restart();

        int64_t microsecond();

        double milliseconds();

        double seconds();

    private:
        std::chrono::system_clock::time_point currentPoint;
    };
}

#endif //NLECONSOLE_NLETIMER_H
