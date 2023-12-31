//
//  vc_event_listener.h

#ifndef vc_event_listener_h
#define vc_event_listener_h

#include "vc_base.h"

VC_NAMESPACE_BEGIN

typedef enum : int {
    EventKeyAbrPredictResult = 10,
} EventKey;

class IVCEventListener {
public:
    virtual ~IVCEventListener(void) {}

public:
    virtual void onEvent(const std::string &mediaId,
                         int key,
                         int value,
                         const std::string &info) = 0;
    virtual void onEventLog(const std::string &eventName,
                            const std::string &logInfo) = 0;
};

VC_NAMESPACE_END
#endif /* vc_event_listener_h */
