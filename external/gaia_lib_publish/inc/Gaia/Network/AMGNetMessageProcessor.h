#pragma once

#include "Gaia/AMGPrerequisites.h"
#include <vector>
#include <string>
NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Message for socket
 */
class NetMessage
{
public:
    std::string content;
};

/**
 *@brief message process for send and receive base class.
*/
class GAIA_LIB_EXPORT NetMessageProcessor
{
public:
    /**
     * @brief Constructor
     */
    NetMessageProcessor();

    /**
     * @brief Destructor
     */
    virtual ~NetMessageProcessor();

    /**
     * @brief process message beforce send message
     *@param message message to send
     * @return std::string message processed
     */
    std::string processSendMessage(const std::string& message);

    /**
     * @brief process message received from socket
     *@param messageSlice message slice from socket
     * @return std::vector<NetMessage> message list receive from socket.
     */
    std::vector<NetMessage> processReceiveMessage(const std::string& messageSlice);

private:
    virtual std::string _processSendMessage(const std::string& message);
    virtual std::vector<NetMessage> _processReceiveMessage(const std::string& messageSlice);
};

NAMESPACE_AMAZING_ENGINE_END
