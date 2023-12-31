
//
// Created by William.Hua on 2021/1/26.
//

#pragma once
#include "me_thread.h"
#include <atomic>
#include <thread>
#include <future>
#include <vector>
#include <chrono>
using namespace std;

namespace mammon
{
class TimeSliceClient
{
public:
    virtual ~TimeSliceClient() = default;

    virtual int useTimeSlice() = 0;

    std::chrono::steady_clock::time_point next_call_time;
};

class TimeSliceThread : public Thread
{
public:
    ~TimeSliceThread();

    void addTimeSliceClient(TimeSliceClient* client);

    void removeClient(TimeSliceClient* client);

    void clearClients();

    int getNumClient() const;

    TimeSliceClient* getClient(int index);

    virtual void run();

private:
    void addTimeSliceClientIfNotExist(TimeSliceClient* client);

    void removeTimeSliceClientIfExist(TimeSliceClient* client);

    TimeSliceClient* getNextClient(int index);

    std::vector<TimeSliceClient*> clients_;
    TimeSliceClient* client_being_called_{nullptr};
    std::mutex mutex_clients_;
    std::mutex mutex_callback_;
};
}
