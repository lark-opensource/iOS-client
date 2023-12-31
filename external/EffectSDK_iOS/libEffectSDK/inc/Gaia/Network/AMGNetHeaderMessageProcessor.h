#pragma once

#include <string>
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Network/AMGNetMessageProcessor.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 *@brief message process for send and receive use uint64_t.
*/
class GAIA_LIB_EXPORT HeaderMessageProcessor : public NetMessageProcessor
{
public:
    /**
     * @brief Constructor
     */
    HeaderMessageProcessor();

    /**
     * @brief Destructor
     */
    virtual ~HeaderMessageProcessor();

private:
    virtual std::string _processSendMessage(const std::string& message);
    virtual std::vector<NetMessage> _processReceiveMessage(const std::string& messageSlice);
    virtual bool _processOneMessage(const std::string& messageSlice, size_t headSize, size_t messageSliceSize, size_t& cursor, NetMessage& message);
    size_t _getMessageLength(const std::string& msg, size_t cursor);
    std::string m_brokenMessage = "";
    size_t m_brokenMessageCompleteSize = 0;
};

NAMESPACE_AMAZING_ENGINE_END
