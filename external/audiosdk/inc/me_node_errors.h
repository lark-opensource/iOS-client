#pragma once

#include <tuple>
#include <deque>
#include <memory>
#include "me_rendercontext.h"
#include "mammon_engine_defs.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

class Node;

/**
 * @brief 错误记录
 * 包含了发生错误的节点指针、端口号、错误码
 */
using NodeErrorRecord = std::tuple<std::shared_ptr<Node>, size_t, int, RenderContext>;

/**
 * @brief 存放错误记录的容器
 * 由Executor所有，通过RenderContext将Executor传递给Node
 */
class MAMMON_EXPORT ErrorRecords {
public:
    /**
     * @brief 获取错误队列头部的错误信息
     *
     * @return NodeErrorRecord
     */
    inline NodeErrorRecord peekError() {
        return errors_.front();
    }

    /**
     * @brief 获取错误队列头部的错误信息并删除
     *
     * @return NodeErrorRecord
     */
    inline NodeErrorRecord popError() {
        auto e = errors_.front();
        errors_.pop_front();
        return e;
    }

    /**
     * @brief 推入一个错误信息到错误队列里
     *
     * @param record
     */
    inline void pushError(NodeErrorRecord&& record) {
        // TODO: 后面可以增加熔断机制，防止上报过多数据
        auto size = errors_.size();
        if (size > 100) {
            errors_.pop_front();
            errors_.emplace_back(record);
        } else {
            errors_.emplace_back(record);
        }
    }

    /**
     * @brief Graph运行过程中是否有错误
     *
     * @return true
     * @return false
     */
    inline bool hasError() const {
        return !errors_.empty();
    }

private:
    std::deque<NodeErrorRecord> errors_;
};

MAMMON_ENGINE_NAMESPACE_END
