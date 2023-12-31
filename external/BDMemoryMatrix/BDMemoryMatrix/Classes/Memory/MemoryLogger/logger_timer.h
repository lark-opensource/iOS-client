//
//  logger_timer.h
//  BDMemoryMatrix
//
//  Created by Ysurfer on 2023/4/24.
//

#ifndef logger_timer_h
#define logger_timer_h

#include <stdio.h>

#include <functional>
#include <chrono>
#include <thread>
#include <atomic>
#include <memory>
#include <mutex>
#include <condition_variable>

#ifdef DEBUG
#define matrix_printf(...) printf(__VA_ARGS__)
#else
#define matrix_printf(...)
#endif

class Timer
{
public:
    Timer(): _expired(true), _try_to_expire(false)
    {}

    Timer(const Timer& timer)
    {
        _expired = timer._expired.load();
        _try_to_expire = timer._try_to_expire.load();
    }

    ~Timer()
    {
        stop();
    }

    void start(int interval, std::function<void()> task)
    {
        // is started, do not start again
        if (_expired == false)
            return;

        // start async timer, launch thread and wait in that thread
        _expired = false;
        std::thread([this, interval, task]() {
           // bool x = _try_to_expire.load(std::memory_order_relaxed);
           // printf("%d",x);
            while (!_try_to_expire)
            {
                // sleep every interval and do the task again and again until times up
                std::this_thread::sleep_for(std::chrono::seconds(interval));
                task();
            }

            {
                // timer be stopped, update the condition variable expired and wake main thread
                std::lock_guard<std::mutex> locker(_mutex);
                _expired = true;
                _expired_cond.notify_one();
            }
        }).detach();
        matrix_printf("timer start\n");
    }

    void startOnce(int delay, std::function<void()> task)
    {
        std::thread([delay, task]() {
            std::this_thread::sleep_for(std::chrono::milliseconds(delay));
            task();
        }).detach();
    }

    void stop()
    {
        // do not stop again
        if (_expired)
            return;

        if (_try_to_expire)
            return;

        // wait until timer
        _try_to_expire = true; // change this bool value to make timer while loop stop
        {
            std::unique_lock<std::mutex> locker(_mutex);
            _expired_cond.wait(locker, [this] {return _expired == true; });

            // reset the timer
            if (_expired == true)
                _try_to_expire = false;
        }
    }

private:
    std::atomic<bool> _expired; // timer stopped status
    std::atomic<bool> _try_to_expire; // timer is in stop process
    std::mutex _mutex;
    std::condition_variable _expired_cond;
};

#endif /* logger_timer_h */
