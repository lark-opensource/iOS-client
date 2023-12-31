//
// Created by ByteDance on 2022/9/30.
//

#ifndef VIDEOENGINE_VC_EVENT_LOG_MANAGER_H
#define VIDEOENGINE_VC_EVENT_LOG_MANAGER_H

#include "vc_event_log_keys.h"
#include "vc_object.h"
#include "vc_shared_mutex.h"

#include <list>

VC_NAMESPACE_BEGIN

class VCEventLogManager {
public:
    VCEventLogManager();
    ~VCEventLogManager();

    void eventLog(const std::string &traceId, int key, int value);
    void eventLog(const std::string &traceId,
                  int key,
                  int value,
                  const std::string &logInfo);

    void removeData(const std::string &traceId);

    std::string getEventLog(const std::string &traceId);

private:
    std::shared_ptr<Dict> putDictIfAbsentAndGet(std::shared_ptr<Dict> &map,
                                                const std::string &key);

private:
    static const int MAX_EVENT_LOG_TRACE_COUNT = 5;

private:
    std::mutex mMutex;
    std::map<std::string, std::shared_ptr<Dict>> mTraceIdMap;
    std::list<std::string> mListTraceId;
    std::shared_ptr<Dict> mNoTraceIdMap;
    std::list<std::string> mUnexpectedThrowbles;
};

VC_NAMESPACE_END
#endif // VIDEOENGINE_VC_EVENT_LOG_MANAGER_H
