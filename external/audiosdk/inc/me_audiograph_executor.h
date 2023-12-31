#pragma once
#include "me_node_errors.h"
#if defined(ENABLE_MAMMON_NODE_CACHE)
#include "me_node_cache_manager.h"
#endif
#include <memory>

MAMMON_ENGINE_NAMESPACE_BEGIN

enum class GraphProcessStatus { kOK, kError };

class MAMMON_EXPORT AudioGraphExecutor {
public:
    AudioGraphExecutor() : errorRecords(nullptr), currentStatus(GraphProcessStatus::kOK) {
    }

    ErrorRecords* errorRecords;
#if defined(ENABLE_MAMMON_NODE_CACHE)
    std::unique_ptr<NodeCacheManager> nodeCacheManager;
#endif
    GraphProcessStatus currentStatus;
};

MAMMON_ENGINE_NAMESPACE_END
