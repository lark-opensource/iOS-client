//
// Created by zhangyeqi on 2019-12-10.
//

#ifndef CUTSAMEAPP_STREAMCONTEXT_H
#define CUTSAMEAPP_STREAMCONTEXT_H

#include <cut/ComLogger.h>
#include <map>
#include <pthread.h>

namespace asve {
    class StreamContext {
    public:
        StreamContext() {
            pthread_mutex_init(&_progressLock, NULL);
            pthread_mutex_init(&_callbackLock, NULL);

        }
        
        virtual ~StreamContext() {
            pthread_mutex_destroy(&_progressLock);
            pthread_mutex_destroy(&_callbackLock);
        }

        void cancel() {
            cancelled = true;
            for (const auto& kv : mCallbackMap) {
                kv.second();
            }
        }

        bool isCancel() {
            return cancelled;
        }

        int getStreamFunctionCount() {
            return streamFunctionCount;
        }
        typedef std::function<void (void)> CanceledCallback;
        void addCanceledCallback(std::uintptr_t handle, CanceledCallback callback) {
            pthread_mutex_lock(&_callbackLock);
            mCallbackMap[handle] = callback;
            pthread_mutex_unlock(&_callbackLock);
        }
        
        void removeCanceledCallback(std::uintptr_t handle) {
            pthread_mutex_lock(&_callbackLock);
            if (mCallbackMap.count(handle)) {
                mCallbackMap.erase(handle);
            }
            pthread_mutex_unlock(&_callbackLock);
        }

        template<typename IN, typename OUT> friend class Stream;
        template<typename IN, typename OUT> friend class StreamFunction;

    private:
        int streamFunctionCount = 0;
        std::map<int, int64_t> progressMap;
        int64_t progress = 0;
        std::map<std::uintptr_t, CanceledCallback> mCallbackMap; //后续扩展不同事件改变value类型
        void updateProgress(int functionIndex, int64_t progress) {
            pthread_mutex_lock(&_progressLock);
            progressMap[functionIndex] = progress;
            // LOGGER->d("----------------------------");
            int64_t progressSum = 0;
            for(const auto& item : progressMap) {
                // LOGGER->d("updateProgress : index=%d, value=%d, count=%d", item.first, item.second, streamFunctionCount);
                progressSum += item.second;
            }
            this->progress = progressSum / streamFunctionCount; // 求平均
            // LOGGER->d("----------------------------");
            pthread_mutex_unlock(&_progressLock);
        }
        int64_t getProgress() {
            pthread_mutex_lock(&_progressLock);
            int64_t _progress = progress;
            pthread_mutex_unlock(&_progressLock);
            return _progress;
        }

        bool cancelled = false;
        pthread_mutex_t _progressLock;
        pthread_mutex_t _callbackLock;
    };

}

#endif //CUTSAMEAPP_STREAMCONTEXT_H
