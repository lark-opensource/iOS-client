#pragma once

#include "Gaia/AMGPrerequisites.h"
#include <vector>
#include <unordered_map>
#include <string>
#include <functional>

// User call the create socket interface when socket has been created.
//NET_ERROR(TTNET_SOCKET_ALREADY_EXIST, -590)
// User input invalid host or port.
//NET_ERROR(TTNET_SOCKET_INVALID_HOST_PORT, -591)
// User call the connect/accept operation again during the progress.
//NET_ERROR(TTNET_SOCKET_OPERATE_IN_PROGRESS, -592)
// User call the tcp client connect interface when connection has been built.
//NET_ERROR(TTNET_SOCKET_ALREADY_CONNECTED, -593)
// User call the tcp client operation interfaces before socket has connnected.
//NET_ERROR(TTNET_SOCKET_NOT_CONNECTED, -594)
// User call the operation interfaces before socket has been created.
//NET_ERROR(TTNET_SOCKET_NOT_CREATE, -595)

NAMESPACE_AMAZING_ENGINE_BEGIN

class NetMessage;
class NetMessageProcessor;

/**
 *@brief socket client info.
*/
class ClientInfo
{
public:
    std::string IP;
    uint32_t clientId = 0;
};

using ClientConnectCallback = std::function<void(const ClientInfo& clientInfo)>;
using ClientDisConnectCallback = std::function<void(const ClientInfo& clientInfo)>;
using ReceivedClientMessageCallback = std::function<void(const ClientInfo& clientInfo, const NetMessage& message)>;
using OnReceiveClientMessageCallback = std::function<void(std::string)>;

/**
 *@brief TCP socket server wrapper.
*/
class GAIA_LIB_EXPORT P2PService
{
public:
    /**
     *@brief Constructor.
    */
    P2PService();

    /**
     * @brief Destructor
     */
    ~P2PService();

    /**
     * @brief Set a message processor.
     * @param processor  NetMessageProcessor
     * @return bool set result
     */
    bool setMessageProcessor(const std::shared_ptr<NetMessageProcessor>& processor);

    /**
     * @brief Set a callback for a client connected
     * @param callback  client connect callback
     * @return bool set result
     */
    bool setClientConnectCallback(const ClientConnectCallback&& callback);

    /**
     * @brief Set a callback for a client disconnected
     * @param callback  client disconnect callback
     * @return bool set result
     */
    bool setClientDisConnectCallback(const ClientDisConnectCallback&& callback);

    /**
     * @brief socket listen to accept client
     * @param port  bind listen port
     * @return bool listen result
     */
    bool listen(int32_t port);

    /**
     * @brief broadcast message to all clients
     * @param message   message to broadcast
     * @return bool broadcast result
     */
    bool broadcastMessage(const std::string& message);

    /**
     * @brief server stop listen client
     */
    void stopListen();

    /**
     * @brief server stop listen client
     * @param num number of max player
     */
    void setPlayerNumMax(int num);

    /**
     * @brief set client message received callback
     * @param callback   handle client message received
     */
    void setOnReceiveClientMessageCallback(const OnReceiveClientMessageCallback&& callback);

private:
    inline bool isPlayerNumLessthenMax() { return m_onlinePlayerNumCurrent < m_onlinePlayerNumMax; }
    inline void addPlayer() { ++m_onlinePlayerNumCurrent; }
    inline void reducePlayer() { --m_onlinePlayerNumCurrent; }
    const int DEFAULT_PLAYER_MAX_NUM = 1;
    int m_onlinePlayerNumMax = DEFAULT_PLAYER_MAX_NUM;
    int m_onlinePlayerNumCurrent = 0;
    std::shared_ptr<NetMessageProcessor> m_messageProcessor;

    // Cronet_TcpServerSocketPtr
    void* m_tcpServer = nullptr;
    class AcceptedClientInfo;
    class TcpClientCallbackDelegate;
    class TcpServerCallbackDelegate;
    std::unique_ptr<TcpServerCallbackDelegate> m_serverCallbackDelegate;
    ClientConnectCallback m_clientConnectCallback = nullptr;
    ClientDisConnectCallback m_clientDisConnectCallback = nullptr;
    OnReceiveClientMessageCallback m_OnReceiveClientMessageCallback = nullptr;
};

NAMESPACE_AMAZING_ENGINE_END
