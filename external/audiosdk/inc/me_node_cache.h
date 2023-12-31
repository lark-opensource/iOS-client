//
// Created by LIJING on 2021/7/8.
//

#pragma once
#ifndef SAMI_CORE_NODE_CACHE_H
#define SAMI_CORE_NODE_CACHE_H

#include "mammon_engine_type_defs.h"
#include "me_audiostream.h"
#include "me_rendercontext.h"
#include "mammon_engine_defs.h"
#include <atomic>
#include <memory>

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 节点缓存抽象类
 *
 */
class MAMMON_EXPORT NodeCache {
public:
    virtual ~NodeCache() = default;
    virtual const AudioStream* getCache(RenderContext& rc) = 0;
    virtual void updateCache(const AudioStream& ac, RenderContext& rc) = 0;
    virtual void clearPrevious(const RenderContext& rc) = 0;
    virtual void clear() = 0;
};

/**
 * @brief 单节点缓存
 *
 * 仅保存一个缓存
 */
class MAMMON_EXPORT SingleNodeCache : public NodeCache{
public:
    SingleNodeCache();
    SingleNodeCache(const AudioStream& ac, RenderContext& rc);
    SingleNodeCache(const SingleNodeCache& other) = delete;
    SingleNodeCache& operator=(const SingleNodeCache& other) = delete;
    SingleNodeCache(SingleNodeCache&& node) : impl(std::move(node.impl)) { }

    RenderContext& getRenderContext();

    virtual const AudioStream* getCache(RenderContext& rc) override;
    virtual void updateCache(const AudioStream& ac, RenderContext& rc) override;
    virtual void clearPrevious(const RenderContext& rc) override;
    virtual void clear() override;

private:
    class Impl;
    std::shared_ptr<Impl> impl;
};

#if !defined(__APPLE__) && defined(ENABLE_MULTIPORT_FIFO)
/**
 * @brief 多节点缓存
 *
 * 保存不同rc的多个缓存
 *
 */
class MAMMON_EXPORT MultiNodeCache : public NodeCache{
public:
    MultiNodeCache();
    MultiNodeCache(const AudioStream& ac, RenderContext& rc);
    MultiNodeCache(const SingleNodeCache& other) = delete;
    MultiNodeCache& operator=(const SingleNodeCache& other) = delete;
    MultiNodeCache(MultiNodeCache&& node) : impl(std::move(node.impl)) { }

    virtual const AudioStream* getCache(RenderContext& rc) override;
    virtual void updateCache(const AudioStream& ac, RenderContext& rc) override;
    virtual void clearPrevious(const RenderContext& rc) override;
    virtual void clear() override;

private:
    class Impl;
    std::shared_ptr<Impl> impl;
};

#endif



MAMMON_ENGINE_NAMESPACE_END

#endif  //SAMI_CORE_NODE_CACHE_H
