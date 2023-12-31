//
// Created by wangchengyi.1 on 2021/5/7.
//

#ifndef DAVINCIRESOURCEDEMO_DAVTHREADPOOL_H
#define DAVINCIRESOURCEDEMO_DAVTHREADPOOL_H

#include <functional>
#include <future>
#include <mutex>
#include <queue>
#include <thread>
#include <utility>
#include <vector>
#include <utility>
#include <chrono>
#include <atomic>

#include "DAVTaskQueue.h"

namespace davinci {
    namespace executor {
        class DAV_EXECUTOR_EXPORT DAVThreadPool {
        private:
            class DAVThreadWorker {
            private:
                int m_id;
                DAVThreadPool *m_pool;
            public:
                DAVThreadWorker(DAVThreadPool *pool, const int id)
                        : m_pool(pool), m_id(id) {
                }

                void operator()() {
                    std::pair<long long, std::function<void()>> item;
                    bool dequeued;
                    while (!m_pool->m_shutdown) {
                        {
                            std::unique_lock<std::mutex> lock(m_pool->m_conditional_mutex);
                            dequeued = false;
                            while (!m_pool->m_shutdown && m_pool->m_queue.empty()) {
                                m_pool->m_conditional_lock.wait(lock);
                            }
                            if (m_pool->m_shutdown) {
                                return;
                            }
                            long long currentMs = std::chrono::duration_cast<std::chrono::milliseconds>(
                                    std::chrono::system_clock::now().time_since_epoch()
                            ).count();
                            long long nextTime = m_pool->m_queue.dequeue(item, currentMs);
                            if (nextTime > 0) {
                                if (nextTime > currentMs) {
                                    dequeued = false;
                                    if (!m_pool->m_shutdown) {
                                        m_pool->m_conditional_lock.wait_for(lock, std::chrono::milliseconds(
                                                nextTime - currentMs));
                                    }
                                } else {
                                    dequeued = true;
                                }
                            }
                        }
                        if (!m_pool->m_shutdown && dequeued) {
                            item.second();
                        }
                    }
                }
            };

            std::atomic<bool> m_shutdown;
            DAVTaskQueue m_queue;
            std::vector<std::thread> m_threads;
            std::mutex m_conditional_mutex;
            std::condition_variable m_conditional_lock;
        public:
            DAVThreadPool(const int n_threads)
                    : m_threads(std::vector<std::thread>(n_threads)), m_shutdown(false) {
            }

            DAVThreadPool(const DAVThreadPool &) = delete;

            DAVThreadPool(DAVThreadPool &&) = delete;

            DAVThreadPool &operator=(const DAVThreadPool &) = delete;

            DAVThreadPool &operator=(DAVThreadPool &&) = delete;

            ~DAVThreadPool() {
                shutdown();
            }

            // Inits thread pool
            void init() {
                for (int i = 0; i < m_threads.size(); ++i) {
                    m_threads[i] = std::thread(DAVThreadWorker(this, i));
                }
            }

            // Waits until threads finish their current task and shutdowns the pool
            void shutdown() {
                if (m_shutdown) {
                    return;
                }
                m_shutdown = true;
                m_conditional_lock.notify_all();

                for (int i = 0; i < m_threads.size(); ++i) {
                    if (m_threads[i].joinable()) {
                        m_threads[i].join();
                    }
                }
            }

            // Submit a function to be executed asynchronously by the pool
            template<typename F, typename...Args>
            auto submit(F &&f, Args &&... args) -> std::future<decltype(f(args...))> {
                // Create a function with bounded parameters ready to execute
                std::function<decltype(f(args...))()> func = std::bind(std::forward<F>(f), std::forward<Args>(args)...);
                // Encapsulate it into a shared ptr in order to be able to copy construct / assign
                auto task_ptr = std::make_shared<std::packaged_task<decltype(f(args...))()>>(func);

                // Wrap packaged task into void function
                std::function<void()> wrapper_func = [task_ptr]() {
                    (*task_ptr)();
                };

                long long currentMs = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::system_clock::now().time_since_epoch()
                ).count();
                auto item = std::pair<long long, std::function<void()>>(currentMs, wrapper_func);

                // Enqueue generic wrapper function
                m_queue.enqueue(item);

                // Wake up one thread if its waiting
                m_conditional_lock.notify_one();

                // Return future from promise
                return task_ptr->get_future();
            }

            template<typename F, typename...Args>
            auto postDelay(long long delayMillis, F &&f, Args &&... args) -> std::future<decltype(f(args...))> {
                // Create a function with bounded parameters ready to execute
                std::function<decltype(f(args...))()> func = std::bind(std::forward<F>(f), std::forward<Args>(args)...);
                // Encapsulate it into a shared ptr in order to be able to copy construct / assign
                auto task_ptr = std::make_shared<std::packaged_task<decltype(f(args...))()>>(func);

                // Wrap packaged task into void function
                std::function<void()> wrapper_func = [task_ptr]() {
                    (*task_ptr)();
                };

                long long currentMs = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::system_clock::now().time_since_epoch()
                ).count();

                auto item = std::pair<long long, std::function<void()>>(currentMs + delayMillis, wrapper_func);

                // Enqueue generic wrapper function
                m_queue.enqueue(item);

                // Wake up one thread if its waiting
                m_conditional_lock.notify_one();

                // Return future from promise
                return task_ptr->get_future();
            }

            void submit(const std::function<void()> &fuc) {
                std::function<void()> wrapper_func = [fuc]() {
                    fuc();
                };
                std::chrono::milliseconds ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::system_clock::now().time_since_epoch()
                );
                auto item = std::pair<long long, std::function<void()>>(ms.count(), wrapper_func);
                m_queue.enqueue(item);
            }
        };
    }
}

#endif //DAVINCIRESOURCEDEMO_DAVTHREADPOOL_H
