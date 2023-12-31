//
// Created by zhangyeqi on 2019-12-03.
//

#ifndef CUTSAMEAPP_EXECUTOR_H
#define CUTSAMEAPP_EXECUTOR_H

#include <functional>
#include <thread>
#include <queue>
#include <stdatomic.h>
#include <mutex>

using std::queue;
using std::function;
using std::string;
using std::shared_ptr;
using std::mutex;
using std::move;
using std::condition_variable;

namespace asve {

    typedef function<void()> Runnable;

    /**
     * Runnable + name 方便分析定位问题
     */
    class Executable {
    public:
        Executable(const string& name, Runnable runnable) : name(name), runnable(move(runnable)) {
        }

        // 直接调用 成员 runnable
        void operator()() const {
            runnable();
        }

        const string& getName() const {
            return name;
        }

    private:
        const string name;
        const Runnable runnable;
    };

    class Executor {
    public:
        Executor(const string& name) : name(name) {}

        void execute(string name, Runnable runnable) {
            Executable executable{name, runnable};
            execute(executable);
        }

        virtual void execute(const Executable& command) = 0;

        const string& getName() {
            return name;
        }

    private:
        string name;
    };

    /**
     * 简单的单线程执行器，基于 std::thread 实现;
     */
    class SingleStdThreadExecutor : public Executor {
    public:
        SingleStdThreadExecutor(const string &name);

        virtual ~SingleStdThreadExecutor();

        /**
         * 触发执行任务，任务有可能需要排队等候执行；
         */
        void execute(const Executable& command) override;

        /**
         * 停止线程，并且清空队列
         */
        void release();

    private:
        volatile bool quit = false;

        condition_variable* triggerCondition;

        queue<Executable>* runnableQueue;
        mutex* queueLock;

        void threadRun(); // std::thread 入口
    };

    /**
     * 提供三个Executor，分别用于 IO / CPU / Light(轻量级CPU操作)
     */
    class Scheduler {
    private:
        mutex memberLock;

        shared_ptr<Executor> m_io;
        shared_ptr<Executor> m_cpu;
        shared_ptr<Executor> m_light;

    public:
        // 方便的接口：

        void post(Executable command) {
            Light()->execute(command);
        }
        void postIO(Executable command) {
            IO()->execute(command);
        }
        void postCPU(Executable command) {
            CPU()->execute(command);
        }
        void post(string name, Runnable runnable) {
            Light()->execute(name, runnable);
        }
        void postIO(string name, Runnable runnable) {
            IO()->execute(name, runnable);
        }
        void postCPU(string name, Runnable runnable) {
            CPU()->execute(name, runnable);
        }

        /**
         * IO操作密集型任务
         */
        virtual shared_ptr<Executor> IO();

        /**
         * CPU计算密集型任务
         */
        virtual shared_ptr<Executor> CPU();

        /**
         * 支持执行轻量异步任务，不怎么耗时的
         */
        virtual shared_ptr<Executor> Light();
    };
}


#endif //CUTSAMEAPP_EXECUTOR_H
