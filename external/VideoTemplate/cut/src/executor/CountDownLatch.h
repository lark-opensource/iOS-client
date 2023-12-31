//
// Created by zhangyeqi on 2019-12-16.
//

#ifndef CUT_ANDROID_COUNTDOWNLATCH_H
#define CUT_ANDROID_COUNTDOWNLATCH_H

#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>

using std::mutex;
using std::condition_variable;
using std::thread;

namespace asve {
    class CountDownLatch {
    public:
        CountDownLatch(int count) : count(count) {};

        void wait();

        void countDown();

    private:
        int count;
        mutex mtk;
        condition_variable cv;
    };
}

#endif //CUT_ANDROID_COUNTDOWNLATCH_H
