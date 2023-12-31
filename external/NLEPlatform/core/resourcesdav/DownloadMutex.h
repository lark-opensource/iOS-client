//
// Created by panruijie on 2021/9/7.
//

#ifndef SMARTMOVIEDEMO_DOWNLOADMUTEX_H
#define SMARTMOVIEDEMO_DOWNLOADMUTEX_H

#endif //SMARTMOVIEDEMO_DOWNLOADMUTEX_H
#include "string"
#include <mutex>
#include <condition_variable>

namespace TemplateConsumer {

    class DownloadMutex {

        public:

            DownloadMutex();

            void wait();

            void notify_one();

            void notify_all();

            void cancel();

            bool setDoneFlag();

            bool isActive();

        private:

            std::mutex mtx;
            std::condition_variable cond;
            bool isCancel = false;
            bool isDone = false;
    };
};