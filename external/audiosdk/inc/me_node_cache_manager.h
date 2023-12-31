//
// Created by LIJING on 2022/4/19.
//

#ifndef SAMI_CORE_ME_NODE_CACHE_MANAGER_H
#define SAMI_CORE_ME_NODE_CACHE_MANAGER_H

#include "mammon_engine_type_defs.h"
#include "me_audiostream.h"
#include "me_rendercontext.h"
#include "mammon_engine_defs.h"
#include "me_node_cache.h"
#include <atomic>
#include <memory>

MAMMON_ENGINE_NAMESPACE_BEGIN

enum class NodeCacheType { SingleCacheType, MultiCacheType };

/**
 * @brief 节点缓存管理
 *
 */
class MAMMON_EXPORT NodeCacheManager {
public:
    NodeCacheManager(NodeCacheType type);
    NodeCacheManager(const NodeCache& other) = delete;
    NodeCacheManager& operator=(const NodeCache& other) = delete;
    ~NodeCacheManager() = default;

    NodeCacheType getNodeCacheType();

    /**
     * @brief 创建缓存管理器
     *
     * @param type
     */
    static std::unique_ptr<NodeCacheManager> create(NodeCacheType type = NodeCacheType::SingleCacheType);

    const AudioStream* getCache(RenderContext& rc, int nodeId);
    void updateCache(const AudioStream& ac, RenderContext& rc, int nodeId);

    /**
     * @brief 清理之前的所有缓存
     */
    void clearPrevious(const RenderContext& rc);
    void clearPrevious(const RenderContext& rc, int nodeId);

    /**
     * @brief 清理缓存
     */
    void clear(int nodeId);
    void clearAll();

private:
    class Impl;
    std::shared_ptr<Impl> impl;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  //SAMI_CORE_ME_NODE_CACHE_MANAGER_H
