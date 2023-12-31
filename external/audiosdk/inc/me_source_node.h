//
// Created by hw on 2019-07-29.
//

#pragma once

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 数据源接口
 *
 */
class MAMMON_EXPORT SourceNode {
public:
    /**
     * @brief 开始发声
     *
     */
    virtual void start() = 0;
    /**
     * @brief 停止发声
     *
     */
    virtual void stop() = 0;

    /**
     * @brief pause
     */
    virtual void pause() = 0;
    /**
     * @brief 是否在循环
     *
     * @return true
     * @return false
     */
    virtual bool getLoop() const = 0;
    /**
     * @brief 设置循环
     *
     */
    virtual void setLoop(bool) = 0;
};
MAMMON_ENGINE_NAMESPACE_END
