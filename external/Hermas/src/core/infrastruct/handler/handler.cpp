//
// Created by bytedance on 2020/8/24.
//

#include "handler.h"

#include "task_queue.h"
#include "log.h"

namespace hermas {

static constexpr intptr_t MSG_POST = 1;
static constexpr intptr_t MSG_SENDMSG_WHAT = 2;
static constexpr intptr_t MSG_SENDMSG_WHAT_ARG = 3;
static constexpr intptr_t MSG_SENDMSG_WHAT_ARG_OBJ = 4;
static constexpr intptr_t MDG_SENDMSG_WHAT_STOP = 5;

//static std::mutex s_global_handler_mutex;

struct HandlerNode {
    int type;
    Handler::IRunnable * runnable;
    int what;
    int64_t arg1;
    int64_t arg2;
    void * obj;
};

Handler::Handler(bool is_global_handler)
: Handler(is_global_handler ? "global" : "instance", is_global_handler) {}


Handler::Handler(const std::string& name, bool is_global_handler)
: m_name(name), mp_task_queue(nullptr), is_running_(false), m_is_global_handler(is_global_handler) {
    
    mp_task_queue = std::make_unique<TaskQueue>();
    mp_thread = std::thread([this]() {
        is_running_.store(true, std::memory_order_release);
        pthread_setname_np(m_name.c_str());
        while (is_running_.load(std::memory_order_acquire)) {
            // 参数从队列读取
            HandlerNode * p_handler_node = (HandlerNode *) mp_task_queue->pop_front(); // 有 wait 卡住动作
            
            // 解包参数
            auto msg = p_handler_node->type;
            
            switch (msg) {
                case MSG_POST: {
                    p_handler_node->runnable->run();
                }
                    break;
                case MSG_SENDMSG_WHAT:
                case MSG_SENDMSG_WHAT_ARG:
                case MSG_SENDMSG_WHAT_ARG_OBJ: {
                    HandleMessage(p_handler_node->what, p_handler_node->arg1, p_handler_node->arg2, p_handler_node->obj);
                }
                    break;
                case MDG_SENDMSG_WHAT_STOP: {
                    is_running_.store(false, std::memory_order_release);
                    break;
                }
            }
            
            delete p_handler_node;
        }
    });
}

Handler::~Handler() {
    Stop();
}

// 派生类析构必须调用此方法！！不然退出时HandleMessage可能访问到派生类已释放变量
void Handler::Stop() {
    // 确保当前线程正在运行和task_queue都存在，以免发生线程提前退出的case
    if (is_running_.load(std::memory_order_acquire) && mp_task_queue) {
        HandlerNode* p_handler_node = new HandlerNode();
        p_handler_node->type = MDG_SENDMSG_WHAT_STOP;
        mp_task_queue->push_back(p_handler_node, 0);
        
        //收到线程退出信号，等线程任务全部执行完，回收所有handler相关的对象
        if (mp_thread.joinable()) {
            mp_thread.join();
        }
        is_running_ = false;
    }
}

void Handler::Post(IRunnable * runnable, int64_t delay_millis) {
    HandlerNode * p_handler_node = new HandlerNode();
    p_handler_node->type = MSG_POST;
    p_handler_node->runnable = runnable;
    
    mp_task_queue->push_back(p_handler_node, delay_millis);
}

void Handler::SendMsg(int what, int64_t delay_millis) {
    HandlerNode * p_handler_node = new HandlerNode();
    p_handler_node->type = MSG_SENDMSG_WHAT;
    p_handler_node->what = what;
    
    mp_task_queue->push_back(p_handler_node, delay_millis);
}

void Handler::SendMsg(int what, void *obj, int64_t delay_mills) {
    HandlerNode *p_handler_node = new HandlerNode();
    p_handler_node->type = MSG_SENDMSG_WHAT;
    p_handler_node->what = what;
    p_handler_node->obj = obj;
    p_handler_node->arg2 = delay_mills;
    
    mp_task_queue->push_back(p_handler_node, delay_mills);
    
}

void Handler::SendMsg(int what, int64_t arg1, int64_t arg2, int64_t delay_millis) {
    HandlerNode *p_handler_node = new HandlerNode();
    p_handler_node->type = MSG_SENDMSG_WHAT_ARG;
    p_handler_node->what = what;
    p_handler_node->arg1 = arg1;
    p_handler_node->arg2 = arg2;
    
    mp_task_queue->push_back(p_handler_node, delay_millis);
}

void Handler::SendMsg(int what, int64_t arg1, int64_t arg2, void * obj, int64_t delay_millis) {
    HandlerNode *p_handler_node = new HandlerNode();
    p_handler_node->type = MSG_SENDMSG_WHAT_ARG_OBJ;
    p_handler_node->what = what;
    p_handler_node->arg1 = arg1;
    p_handler_node->arg2 = arg2;
    p_handler_node->obj = obj;
    
    mp_task_queue->push_back(p_handler_node, delay_millis);
}

void Handler::HandleMessage(int what, int64_t arg1, int64_t arg2, void * obj) {}

Handler::IRunnable::IRunnable() {}

Handler::IRunnable::~IRunnable() {}

void Handler::IRunnable::run() {}

} //namespace hermas
