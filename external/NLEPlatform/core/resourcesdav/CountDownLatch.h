//
// Created by zhangyeqi on 2019-12-16.
//

#ifndef NLEPLATFORM_COUNTDOWNLATCH_H
#define NLEPLATFORM_COUNTDOWNLATCH_H

#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>

using std::mutex;
using std::condition_variable;
using std::thread;

namespace TemplateConsumer {
    class CountDownLatch {
    public:
        CountDownLatch(int count) : count(count) {}

        virtual ~CountDownLatch();

        void wait();

        int wait_for(int timeout);

        void countDown();

    private:
        int count;
        mutex mtk;
        condition_variable cv;
    };
}

#endif //NLEPLATFORM_COUNTDOWNLATCH_H
