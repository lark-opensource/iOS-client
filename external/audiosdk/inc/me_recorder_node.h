//
// Created by shidephen on 2020/4/23.
//

#pragma once
#ifndef MAMMONSDK_ME_RECORDER_NODE_H
#define MAMMONSDK_ME_RECORDER_NODE_H

#include "mammon_engine_defs.h"
#include <functional>
#include <string>
#include "mammon_engine_type_defs.h"
#include "me_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 从图中任意边写入PCM数据到文件的节点 Write PCM data to a file pass through
 */
class MAMMON_EXPORT RecorderNode : public Node {
public:
    ~RecorderNode();
    // Inherated from Node

    int process(int port, RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::RecorderNode;
    }

    bool cleanUp() override;

    /**
     * @brief Create RecorderNode
     *
     * @param config Format config
     * @param is_async Is data written in async mode.
     * @return std::shared_ptr<RecorderNode>
     */
    static std::shared_ptr<RecorderNode> create(const EncoderFormat& config, bool is_async = true) {
        std::shared_ptr<RecorderNode> node = std::shared_ptr<RecorderNode>(new RecorderNode(config, is_async));
        node->addOutput();
        node->addInput();
        return node;
    }

    /**
     * @brief 开始写入 Start recording
     * Not implement
     */
    void start();

    /**
     * @brief 暂停写入 Pause recording
     * Not implement
     */
    void pause();

    /**
     * @brief 停止写入 Stop recording
     * Not implement
     */
    void stop();

    /**
     * @brief 设置写入的文件路径 Set path to write data.
     *
     * @return true
     * @return false
     */
    bool setPath(std::string);

    /**
     * @brief 获取当前的写入路径 Get current path.
     *
     * @return const std::string&
     */
    const std::string& getPath();

    /**
     * @brief 获得EncoderFormat对象 Get the Format object
     *
     * @return const EncoderFormat&
     */
    const EncoderFormat& getFormat() const;

    /**
     * @brief The callback type
     *
     */
    using WriteFinishedCallback = std::function<void(size_t)>;
    /**
     * @brief 设置写入完成时的回调函数 Set a callback function for this node
     * The function will be invoked when writing stopped.
     * 在真正写入停止时触发回调函数
     * @param callback Callback function
     */
    void setFinishedCallback(WriteFinishedCallback&& callback);

private:
    explicit RecorderNode(const EncoderFormat&, bool async);
    const bool is_async_;
    //    EncoderFormat format_;
    std::string path;
    struct Impl;
    Impl* internal_;
};
}

#endif  // MAMMONSDK_ME_RECORDER_NODE_H
