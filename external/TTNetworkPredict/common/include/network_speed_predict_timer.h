//
// Created by shen chen on 2021/2/26.
//

#ifndef NETWORKPREDICT_NETWORK_SPEED_PREDICT_TIMER_H
#define NETWORKPREDICT_NETWORK_SPEED_PREDICT_TIMER_H

#include "network_speed_pedictor_base.h"
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <thread>
#include <pthread.h>

NETWORKPREDICT_NAMESPACE_BEGIN

using interval_t = std::chrono::milliseconds;

template <typename Function>

class Timer {
    class impl {
        Function func;
        const interval_t interval;
        std::thread thread;
        std::mutex mtx;
        std::condition_variable cvar;
        bool enabled = false;

        void timer() {
#if defined(__APPLE__)
            pthread_setname_np("speedPredictTimer");
#endif
            auto deadline = std::chrono::steady_clock::now() + interval;
            std::unique_lock<std::mutex> lock{mtx};
            while (enabled) {
                if (cvar.wait_until(lock, deadline) == std::cv_status::timeout) {
                    lock.unlock();
                    func();
                    deadline += interval;
                    lock.lock();
                }
            }
        }

    public:
        impl(Function f, interval_t interval)
        : func(std::move(f))
        , interval(std::move(interval)) {
        }

        ~impl() {
            stop();
        }

        void start() {
            if (!enabled) {
                enabled = true;
                thread = std::thread(&impl::timer, this);
            }
        }

        void stop() {
#if defined(__APPLE__)
            if (thread.get_id() != std::this_thread::get_id()) {
#endif
                if (enabled) {
                    std::lock_guard<std::mutex> _{mtx};
                    enabled = false;
                }
                cvar.notify_one();
                if (thread.joinable()) {
                    thread.join();
                }
#if defined(__APPLE__)
            } else {
                enabled = false;
                pthread_exit(nullptr);
            }
#endif
        }
    };

public:
    Timer(Function f, interval_t interval) : pimpl(new impl(std::move(f), std::move(interval))) {
    }

    void start() {
        pimpl->start();
    }

    void stop() {
        pimpl->stop();
    }

private:
    std::unique_ptr<impl> pimpl;
};

NETWORKPREDICT_NAMESPACE_END

#endif //NETWORKPREDICT_NETWORK_SPEED_PREDICT_TIMER_H
