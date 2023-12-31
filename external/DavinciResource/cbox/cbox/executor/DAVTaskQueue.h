//
// Created by wangchengyi.1 on 2021/5/7.
//

#ifndef DAVINCIRESOURCEDEMO_DAVSAFEQUEUE_H
#define DAVINCIRESOURCEDEMO_DAVSAFEQUEUE_H

#include <mutex>
#include <queue>
#include "DAVExecutorExport.h"

namespace davinci {
    namespace executor {
        // Thread safe implementation of a Queue using a std::queue
        class DAV_EXECUTOR_EXPORT TaskCompare {
        public:
            bool operator()(std::pair<long long, std::function<void()>> &v1,
                            std::pair<long long, std::function<void()>> &v2) const {
                return v1.first > v2.first;
            }
        };

        class DAV_EXECUTOR_EXPORT DAVTaskQueue {
        private:
            std::priority_queue<std::pair<long long, std::function<void()>>,
                    std::vector<std::pair<long long, std::function<void()>>>,
                    TaskCompare> m_queue;
            std::mutex m_mutex;
        public:
            DAVTaskQueue() {

            }

            DAVTaskQueue(DAVTaskQueue &other) = delete;

            ~DAVTaskQueue() {

            }


            bool empty() {
                std::unique_lock<std::mutex> lock(m_mutex);
                return m_queue.empty();
            }

            int size() {
                std::unique_lock<std::mutex> lock(m_mutex);
                return m_queue.size();
            }

            void enqueue(std::pair<long long, std::function<void()>> &t) {
                std::unique_lock<std::mutex> lock(m_mutex);
                m_queue.push(t);
            }

            long long dequeue(std::pair<long long, std::function<void()>> &t, long long limit) {
                std::unique_lock<std::mutex> lock(m_mutex);

                if (m_queue.empty()) {
                    return -1;
                }
                if (m_queue.top().first > limit) {
                    return m_queue.top().first;
                }
                t = std::move(m_queue.top());

                m_queue.pop();
                return t.first;
            }
        };
    }
}


#endif //DAVINCIRESOURCEDEMO_DAVSAFEQUEUE_H
