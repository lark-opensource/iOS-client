#pragma once
#include <string>
#include <functional>
#include "Gaia/AMGPrerequisites.h"
NAMESPACE_AMAZING_ENGINE_BEGIN

class NetMessage;
class NetMessageProcessor;

using ErrorCallback = std::function<void(int error)>;
using ConnectCallback = std::function<void()>;
using ReceivedMessageCallback = std::function<void(const std::string& msg)>;

/**
 *@brief TCP socket client wrapper.
 */
class GAIA_LIB_EXPORT P2PClient
{
public:
    /**
     *@brief Constructor.
    */
    P2PClient();

    /**
     * @brief Destructor
     */
    ~P2PClient();

    /**
     * @brief client connect to server
     * @param ip_addr  set server ip
     * @param port set server port
     * @return bool result
     */
    bool connect(const char* ip_addr, int32_t port);

    /**
     * @brief client disconnect
     */
    void disconnect();

    /**
     * @brief client send message to server
     * @param message client message send to server
     * @return bool result
     */
    bool sendMessage(const std::string& message);

    /**
     * @brief set message processor
     * @param processor  for message process
     * @return bool result
     */
    bool setMessageProcessor(const std::shared_ptr<NetMessageProcessor>& processor);

    /**
     * @brief tcp error callback
     * @param errorCallback call  when receive a tcp error
     * @return bool result
     */
    bool setTcpErrorCallback(const ErrorCallback&& errorCallback);

    /**
     * @brief call when client connect to server
     * @param connectCallback  callback for connected to server
     * @return bool result
     */
    bool setConnectCallback(const ConnectCallback&& connectCallback);

    /**
     * @brief callback when receive server message
     * @param receivedMessageCallback  call when receive message from server
     * @return bool result
     */
    bool setReceivedMessageCallback(const ReceivedMessageCallback&& receivedMessageCallback);

private:
    void initExecutor();
    void* m_tcpClientSocket = nullptr;
    std::shared_ptr<NetMessageProcessor> m_messageProcessor;
    ErrorCallback m_tcpErrorCallback = nullptr;
    ConnectCallback m_connectCallback = nullptr;
    ReceivedMessageCallback m_receivedMessageCallback = nullptr;
    class TcpClientCallbackDelegate;
    std::unique_ptr<TcpClientCallbackDelegate> m_tcpClientCallbackDelegate;
};

NAMESPACE_AMAZING_ENGINE_END
