/**
 * @file AMGAPIMessageCenter.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Message queue to store message handler
 * @version 0.1
 * @date 2020-04-20
 *
 * @copyright Copyright (c) 2019
 *
 */
#pragma once
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/AMGRefBase.h"
#include "Gaia/AMGSharePtr.h"
#include "Gaia/MemoryManager/AMGMemoryPool.h"
#include <unordered_map>
#include <mutex>
#include <condition_variable>
#include <list>
#include <thread>
namespace bytedance
{
namespace protobuf
{
class MessageLite;
}
} // namespace bytedance

NAMESPACE_AMAZING_ENGINE_BEGIN
// clang-format off

#define MemoryPoolPtrSize sizeof(void*)

#define MESSAGE_HANDLER_DEF_BEGIN(HandlerName)                                       \
class HandlerName : public MessageHandler                                            \
{                                                                                    \
    HandlerName(const bytedance::protobuf::MessageLite& msg,                         \
                bool needWaitCompleted, void* userdata)                              \
        : MessageHandler(msg, needWaitCompleted, userdata)                           \
    {                                                                                \
    }                                                                                \
                                                                                     \
public:                                                                              \
    static MessageHandler* Instance(MemoryPool* pool,                                \
        const bytedance::protobuf::MessageLite& msg,                                 \
        bool needWaitCompleted, void* userdata)                                      \
    {                                                                                \
        void* ans = pool->allocate();                                                \
        *(MemoryPool**)ans = pool;                                                   \
        void* handlerPtr = (char*)ans + MemoryPoolPtrSize;                           \
        return ::new (handlerPtr) HandlerName(msg, needWaitCompleted, userdata);     \
    }                                                                                \
    void onHandle() override;                                                        \
    void operator delete(void* p)                                                    \
    {                                                                                \
        if (p != nullptr)                                                            \
        {                                                                            \
            p = (char*)p - MemoryPoolPtrSize;                                        \
            MemoryPool* pool = *(MemoryPool**)p;                                     \
            if (pool != nullptr)                                                     \
            {                                                                        \
                pool->deallocate(p);                                                 \
            }                                                                        \
        }                                                                            \
    }                                                                                \
public:

#define MESSAGE_HANDLER_USERDATA_DEF_BEGIN(HandlerName) \
    MESSAGE_HANDLER_DEF_BEGIN(HandlerName)              \
    void onUserData() override;

#define MESSAGE_HANDLER_DEF_END() \
    }                             \
    ;

// clang-format on

/**
 * @brief Message handler is base class of all types of message handlers.
 * Message Handler is to handle one type of message.
 * 
 */
class GAIA_LIB_EXPORT MessageHandler : public RefBase
{
public:
    /**
     * @brief Construct a new Message Handler object
     * 
     * @param msg The protobuf message which store the data.
     * @param needThreadWaiting Wthether need to wait until handle completed.
     * @param userdata The data which not be stored in protobuf message.
     */
    MessageHandler(const bytedance::protobuf::MessageLite& msg, bool needThreadWaiting, void* userdata);

    /**
     * @brief Destroy the Message Handler object.
     * 
     */
    virtual ~MessageHandler();

    /**
     * @brief Get whether need waiting handle completed.
     * 
     * @return true Need waitting.
     * @return false Do not need waiting.
     */
    bool needThreadWaiting()
    {
        return m_needThreadWaiting;
    }

    /**
     * @brief Notify current thread after handlded.
     * 
     */
    void threadNotify();

    /**
     * @brief Block current thread after posting current message.
     * 
     */
    void threadWaiting();

    /**
     * @brief The handle function to process current message.
     * 
     */
    virtual void onHandle() {}

    /**
     * @brief The function to handle user data.
     * 
     */
    virtual void onUserData() {}

protected:
    void* m_userdata = nullptr;
    bytedance::protobuf::MessageLite* m_msg = nullptr;

private:
    std::atomic<bool> m_needThreadWaiting;
    std::atomic<bool> m_isThreadWaiting;
    std::mutex m_mutex;
    std::condition_variable m_condition;
};

class MessageQueue
{
public:
    /**
     * @brief Wait and get one message handler util the queue is not empty.
     * 
     * @return const SharePtr<MessageHandler> The message handler at the front of message list.
     */
    const SharePtr<MessageHandler> waitForMessage();

    /**
     * @brief Get the front message handler of the message list.
     * 
     * @return const SharePtr<MessageHandler> The message handler at the front of message list.
     */
    const SharePtr<MessageHandler> popMessage();
    /**
     * @brief Post one message handler to the back of the message list.
     * 
     * @param msgHandler The message handler to post.
     */
    void postMessage(const SharePtr<MessageHandler> msgHandler);
    /**
     * @brief Get the message handler count in current message queue.
     * 
     * @return int The message handler count.
     */
    int getMessageCount();

private:
    std::mutex m_mutex;
    std::condition_variable m_condition;
    std::list<SharePtr<MessageHandler>> m_messageList;
};

NAMESPACE_AMAZING_ENGINE_END
