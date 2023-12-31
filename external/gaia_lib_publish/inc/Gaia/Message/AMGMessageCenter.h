/**
 * @file AMGMessageCenter.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Message center to handle message.
 * @version 0.1
 * @date 2019-04-20
 *
 * @copyright Copyright (c) 2019
 *
 */

#pragma once
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/AMGSharePtr.h"
#include "Gaia/Message/AMGMessageQueue.h"
#include "Gaia/AMGThreadPool.h"
#include "Gaia/MemoryManager/AMGMemoryPool.h"
NAMESPACE_AMAZING_ENGINE_BEGIN
class MessageCenter;

/**
 * @brief The factory to create message center.
 * 
 */
class GAIA_LIB_EXPORT MessageCenterFactory
{
public:
    /**
     * @brief Construct a new Message Center Factory.
     * 
     */
    MessageCenterFactory();
    /**
     * @brief Create a Message Center.
     * 
     * @param initThreadFunc The init func for new message center which will be processed before message process loop.
     * @return SharePtr<MessageCenter> The new message center.
     */
    SharePtr<MessageCenter> CreateMessageCenter(std::function<void()> initThreadFunc = nullptr);

private:
    ThreadPool m_threadPool;
    std::mutex m_checkThreadMutex;

    std::mutex m_waitRunningMutex;
    std::condition_variable m_waitRunningCondition;
    bool m_threadRunning = false;
};
/**
 * @brief Get the Message Center Factory.
 * 
 * @return MessageCenterFactory& The reference of message center factory.
 */
GAIA_LIB_EXPORT MessageCenterFactory& GetMessageCenterFactory();

#define REGISTER_MESSAGE_HANDLER(MessageCenter, Message, Handler)                       \
    {                                                                                   \
        Message msg;                                                                    \
        String type##Handler = msg.GetTypeName();                                       \
        MessageCenter->registerMessageHandlerFactory(type##Handler, Handler::Instance); \
        MessageCenter->createMessageHandlerPool(type##Handler, sizeof(Handler));        \
    }

class MessageProxy;

/**
 * @brief The defination of message handler factory function.
 * 
 */
typedef MessageHandler* (*MessageHandlerFactory)(MemoryPool*, const bytedance::protobuf::MessageLite&, bool, void*);

class GAIA_LIB_EXPORT MessageCenter : public RefBase
{
public:
    /**
     * @brief Construct the Message Center.
     *
     */
    MessageCenter();
    /**
     * @brief Destroy the Message Center.
     * 
     */
    ~MessageCenter();

    /**
     * @brief The function to call when need to destroy messge center.
     * The function only guarantee stopping the message process loop.
     * 
     */
    void onDestroy();

    /**
     * @brief The function to notify message thread which can be blocked by some message.
     * 
     */
    void notifyMessageThread();

    /**
     * @brief Pause the message center process loop.
     * 
     */
    void onPause();

    /**
     * @brief Resume the message center process loop.
     * 
     */
    void onResume();

    /**
     * @brief Post Message Handler.
     * 
     * @param msgHandler The message handler to post.
     */
    void postMessage(SharePtr<MessageHandler> msgHandler);

    /**
     * @brief Register the mapping between message type and message handler factory.
     * 
     * @param messageType The message type.
     * @param factory The message handler factory.
     */
    void registerMessageHandlerFactory(String& messageType, MessageHandlerFactory factory);
    /**
     * @brief Create a message handler pool for one message type.
     * 
     * @param messageType The message type.
     * @param blockSize The block size of memory pool for message type.
     */
    void createMessageHandlerPool(String& messageType, int blockSize);
    /**
     * @brief Get a message handler from the factory. 
     * 
     * @param msg The message.
     * @param needWaitCompleted Wthether need wait for handling completed.
     * @param userData The user data of message.
     * @return MessageHandler* The created message handler for input param.
     */
    MessageHandler* getMessageHandlerFromFactory(const bytedance::protobuf::MessageLite& msg, bool needWaitCompleted, void* userData);

    /**
     * @brief The message process loop fucntion.
     * 
     */
    void processMessageLoop();

private:
    MessageQueue m_messageQueue;

    std::mutex m_mutex;
    std::condition_variable m_condition;
    std::atomic<bool> m_threadStopped;
    std::atomic<bool> m_threadPausing;
    std::atomic<bool> m_threadLocking;
    std::unordered_map<String, MessageHandlerFactory> m_msgHandlerFactories;
    std::unordered_map<String, MemoryPool*> m_msgHandlerPools;
};

/**
 * @brief Message proxy is the helper for users to post message easily.
 * 
 */
class GAIA_LIB_EXPORT MessageProxy
{
public:
    /**
     * @brief Construct a new Message Proxy object
     * 
     * @param messageCenter The message center pointer.
     * @param msg The message to post.
     * @param processBeforeMessage The process need to be done before posting message.
     * @param processAfterMessage The process need to be done after posting message.
     * @param userdata The user data of current message.
     */
    MessageProxy(SharePtr<MessageCenter> messageCenter, bytedance::protobuf::MessageLite* msg,
                 std::function<void()> processBeforeMessage, std::function<void()> processAfterMessage, void* userdata);

    /**
     * @brief Destroy the message proxy.
     * 
     */
    ~MessageProxy();

    /**
     * @brief Get the Message.
     * 
     * @return const bytedance::protobuf::MessageLite* The message in current proxy.
     */
    const bytedance::protobuf::MessageLite* getMessage() const { return m_msg; }

    /**
     * @brief Get need waiting completed.
     * 
     * @return true Need waittng completed.
     * @return false Do not need waiting completed.
     */
    bool isNeedWaitCompleted() const { return m_processAfterMessage != nullptr; }

    /**
     * @brief Post message.
     * 
     */
    void postMessage();

    /**
     * @brief Get message handler of current message.
     * 
     * @return SharePtr<MessageHandler> The message handler in current message proxy.
     */
    SharePtr<MessageHandler> getMessageHandler() { return m_msgHandler; }

    /**
     * @brief Get the user of current message.
     * 
     * @return void* The user in current proxy.
     */
    void* getUserdata() { return m_userdata; }

private:
    bytedance::protobuf::MessageLite* m_msg = nullptr;
    std::function<void()> m_processBeforeMessage = nullptr;
    std::function<void()> m_processAfterMessage = nullptr;
    SharePtr<MessageCenter> m_messageCenter = nullptr;
    SharePtr<MessageHandler> m_msgHandler = nullptr;
    void* m_userdata = nullptr;
};

NAMESPACE_AMAZING_ENGINE_END
