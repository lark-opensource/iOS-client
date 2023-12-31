//
//  Thread.h
//  testAssetSystem
//
//  Created by 敖建 on 2018/8/19.
//  Copyright © 2018年 敖建. All rights reserved.
//

#ifndef Thread_h
#define Thread_h

#include "Gaia/AMGPrerequisites.h"
#include "Gaia/AMGRefBase.h"
#include "Gaia/Thread/AMGThreadFactory.h"
#include <queue>
#include <deque>
#include <functional>
#include <future>

NAMESPACE_AMAZING_ENGINE_BEGIN

#define THREADPOOL_MAX_NUM 15 //线程池最大线程数量

struct AETask
{
    using Task = std::function<void()>;
    Task task;
    int32_t name = INT32_MIN;
    AETask(Task _task, int32_t _name)
        : task(_task)
        , name(_name)
    {
    }
};

class GAIA_LIB_EXPORT ThreadPool : public RefBase
{
private:
    std::vector<ThreadWrapper*> mThreadPool;
    std::deque<AETask> mTasks;

    std::vector<AETask::Task> mInitFunc;
    std::vector<AETask::Task> mDeinitFunc;

    std::mutex mMutex;
    std::condition_variable mCondition;
    std::atomic<bool> mbRun;
    std::atomic<int> mnIdleThread; //空闲线程数量
    int mnTotalThread;

public:
    ThreadPool(int32_t numThread = 3);
    virtual ~ThreadPool();

    void run();

    inline int32_t GetNumThread() const
    {
        return (int32_t)mThreadPool.size();
    }

    inline int32_t GetNumIdleThread() const
    {
        return mnIdleThread;
    }

    void clearAllTask();

    void clearTask(int32_t name);

    //注册init到线程池的每个线程
    template <class F, class... Args>
    void registerToEachThread(F&& f, Args&&... args)
    {
        using RetType = decltype(f(args...));                                                                                    // typename std::result_of<F(Args...)>::type, 函数 f 的返回值类型
        auto task = std::make_shared<std::packaged_task<RetType()>>(std::bind(std::forward<F>(f), std::forward<Args>(args)...)); // 把函数入口及参数,打包(绑定)

        mInitFunc.push_back([task]() { (*task)(); });
    }

    //注册任务到线程池的每个线程
    template <class F, class... Args>
    void unregisterToEachThread(F&& f, Args&&... args)
    {
        using RetType = decltype(f(args...));                                                                                    // typename std::result_of<F(Args...)>::type, 函数 f 的返回值类型
        auto task = std::make_shared<std::packaged_task<RetType()>>(std::bind(std::forward<F>(f), std::forward<Args>(args)...)); // 把函数入口及参数,打包(绑定)
        mDeinitFunc.push_back([task]() { (*task)(); });
    }

    //提交任务到队首
    template <class F, class... Args>
    auto preemptCommit(int32_t name, F&& f, Args&&... args) -> std::future<decltype(f(args...))>
    {
        if (!mbRun)
        {
            return std::future<void>();
        }
        using RetType = decltype(f(args...));                                                                                    // typename std::result_of<F(Args...)>::type, 函数 f 的返回值类型
        auto task = std::make_shared<std::packaged_task<RetType()>>(std::bind(std::forward<F>(f), std::forward<Args>(args)...)); // 把函数入口及参数,打包(绑定)
        std::future<RetType> future = task->get_future();
        AETask aeTask([task]() { (*task)(); }, name);
        {                                             // 添加任务到队列
            std::lock_guard<std::mutex> lock(mMutex); //对当前块的语句加锁
            mTasks.push_front(aeTask);                // preempt(Task{...}) 放到队列前面
        }
#ifdef THREADPOOL_AUTO_GROW
        if (mnIdleThread < 1 && mThreadPool.size() < THREADPOOL_MAX_NUM)
            addThread(1);
#endif                           // !THREADPOOL_AUTO_GROW
        mCondition.notify_one(); // 唤醒一个线程执行
        return future;
    }

    //提交任务到队尾
    template <class F, class... Args>
    auto commit(int32_t name, F&& f, Args&&... args) -> std::future<decltype(f(args...))>
    {
        if (!mbRun)
        {
            return std::future<void>();
        }
        using RetType = decltype(f(args...));                                                                                    // typename std::result_of<F(Args...)>::type, 函数 f 的返回值类型
        auto task = std::make_shared<std::packaged_task<RetType()>>(std::bind(std::forward<F>(f), std::forward<Args>(args)...)); // 把函数入口及参数,打包(绑定)
        std::future<RetType> future = task->get_future();
        AETask aeTask([task]() { (*task)(); }, name);
        {                                             // 添加任务到队列
            std::lock_guard<std::mutex> lock(mMutex); //对当前块的语句加锁
            mTasks.push_back(aeTask);                 // push(Task{...}) 放到队列后面
        }
#ifdef THREADPOOL_AUTO_GROW
        if (mnIdleThread < 1 && mThreadPool.size() < THREADPOOL_MAX_NUM)
            addThread(1);
#endif                           // !THREADPOOL_AUTO_GROW
        mCondition.notify_one(); // 唤醒一个线程执行
        return future;
    }

#ifdef THREADPOOL_AUTO_GROW
private:
#endif
    void AddThread(int32_t num);
};

NAMESPACE_AMAZING_ENGINE_END
#endif /* Thread_h */
