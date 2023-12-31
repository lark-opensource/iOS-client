//
// Created by hw on 2019-07-29.
//

#pragma once
#ifndef MAMMONSDK_ME_NODE_H
#define MAMMONSDK_ME_NODE_H

#include <memory>
#include <map>
#include <vector>
#include <stdexcept>
#include <atomic>
#include "mammon_engine_type_defs.h"
#include "me_audiostream.h"
#include "me_rendercontext.h"
#include "mammon_engine_defs.h"
#include "me_node_processing_config.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

// TODO: remove final notation of NodeInput & NodeOutput
class Node;
class NodeOutput;
class AudioGraph;

/**
 * @brief 输入端口
 *
 */
class MAMMON_EXPORT NodeInput final {
    using OutputNodeMap = std::map<NodeOutput*, std::shared_ptr<Node>>;

public:
    NodeInput(const std::shared_ptr<Node>& node, size_t port_id, size_t num_chan);

    /**
     * @brief 端口号
     * @return
     */
    size_t portId() const;

    /**
     * @brief 端口通道数
     * @return
     */
    size_t numChannel() const;

    void setChannelCount(size_t ch);
    /**
     * @brief 端口指定输出端口
     * @param output 输出端口
     */
    void disconnect(NodeOutput* output);
    /**
     * @brief 端口所有输出端口的链接
     */
    void disconnectAll();

    const AudioStream* read(RenderContext& rc);

    /**
     * 直接从上一端口读取数据不计算，用于bypass
     * @return 连接的NodeOutput里面的数据
     */
    const AudioStream* passThroughStream();

    /**
     * @brief 获取连接的数量
     *
     * @return int
     */
    size_t getNumConnections() const;

    /**
     * @brief 获取所有连接关系
     *
     * @return const OutputNodeMap&
     */
    const OutputNodeMap& getConnectedPairs() const;

protected:
    void addOutput(NodeOutput* oport);

    bool removeOutput(NodeOutput* oport);

    std::weak_ptr<Node> parent();

private:
    friend class NodeOutput;
    class NodeInputImpl;
    std::shared_ptr<NodeInputImpl> impl;
};

/**
 * @brief 输出端口
 *
 */
class MAMMON_EXPORT NodeOutput final {
    using InputNodeMap = std::map<NodeInput*, std::shared_ptr<Node>>;

public:
    NodeOutput(const std::shared_ptr<Node>& node,
               size_t port_id,
               size_t num_chan);

    /**
     * @return 端口号
     */
    size_t portId() const;

    /**
     * @return 端口通道数
     */
    size_t numChannel() const;

    void setChannelCount(size_t ch);

    int prepare(NodeProcessingConfig config);

    /**
     * @brief 连接一对输出输入
     * @param iport 输入端口
     * @return 被连接的Node的指针, 方便连续调用该函数连接节点
     */
    std::shared_ptr<Node> connect(NodeInput* iport);
    /**
     * 和指定输出端口断开连接
     * @param iport 指定输出端口
     */
    void disconnect(NodeInput* iport);

    void disconnectAll();

    /**
     * 获取当前端口的连接数
     */
    size_t getNumConnections() const;

    /**
     * @brief 获取所有的链接关系
     *
     * @return const InputNodeMap&
     */
    const InputNodeMap& getConnectedPairs() const;

    /**
     * @brief 从当前port拉数据
     * @param rc 拉取范围
     * @return 数据指针，nullptr时相当于直接skip那个节点
     */
    const AudioStream* pull_data(RenderContext& rc);

    AudioStream& getWriteStream();

protected:
    bool removeInput(NodeInput* input);
    void addInput(NodeInput* input);
    std::weak_ptr<Node> parent();

private:
    friend class NodeInput;
    class NodeOutputImpl;
    std::shared_ptr<NodeOutputImpl> impl;
};

/**
 * @brief 节点抽象类
 *
 */
class MAMMON_EXPORT Node : public std::enable_shared_from_this<Node> {
    friend class GraphManager;

public:
    Node();

    virtual ~Node() = default;

    virtual int process(int out_port_id, RenderContext& rc) = 0;

    virtual bool cleanUp();

    int getId() const;

    virtual audiograph::NodeType type() const;

    /**
     * @brief 获取自身实例的智能指针
     *
     * @return std::shared_ptr<Node<T>>
     */
    virtual std::shared_ptr<Node> getSharedPtr() = 0;

    /**
     * @brief 增加输出端口
     * 由于shared_from_this问题，只能从外部把指针传进来
     * @param num_chan 通道数
     */
    virtual std::shared_ptr<Node> addOutput(size_t num_chan = 2);

    /**
     * @brief 增加输入端口
     * 由于shared_from_this问题，只能从外部把指针传进来
     * @param num_chan 通道数
     */
    virtual std::shared_ptr<Node> addInput(size_t num_chan = 2);

    /**
     * @brief 获取目前已有的输入端口数
     *
     * @return size_t
     */
    virtual size_t numInputs() const;

    /**
     * @brief 获取目前已有的输出端口号
     *
     * @return size_t
     */
    virtual size_t numOutputs() const;

    /**
     * @brief 确保输入端口数至少达到了num
     *
     * @param num
     * @param nchan 通道数默认是2
     */
    virtual void ensureInputPorts(size_t num, size_t num_chan = 2);

    /**
     * @brief 确保输出端口数至少达到了num
     *
     * @param num
     * @param nchan 通道数默认是2
     */
    virtual void ensureOutputPorts(size_t num, size_t num_chan = 2);

    /**
     * @brief 是否有输出连接
     *
     * @return true
     * @return false
     */
    virtual bool hasOutputConnections() const;

    /**
     * @brief 是否有输入连接
     * @return
     */
    virtual bool hasInputConnections() const;

    /**
     * @brief 断开所有输入连接
     */
    virtual void disconnectAllInputs();

    /**
     * @brief 断开所有输出连接
     */
    virtual void disconnectAllOutputs();

    /**
     * @brief 获取输入端口指针
     * @param idx 端口号
     * @return
     */
    virtual NodeInput* pin(size_t idx);

    /**
     * @brief 获取输出端口指针
     * @param idx 端口号
     * @return NodeOutput
     */
    virtual NodeOutput* pout(size_t idx);

    /**
     * @brief 连接两个节点，从pout(0)到pin(0)
     *
     * @param rhs 目标节点
     * @return Node* 返回目标节点
     */
    virtual Node* connect(Node* rhs);

    /**
     * @brief 获取当前节点延迟值
     *
     * @return size_t
     */
    virtual size_t getLatency() const;

    /**
     * @brief 获取最大延迟值
     * 最大的延迟值是通过当前节点的所有信号路径中值最大的
     * @return size_t
     */
    virtual size_t getMaxLatency() const;

    /**
     * @brief 获取拥有这个节点的图对象
     *
     * @return AudioGraph*
     */
    AudioGraph* getGraph();

    /**
     * @brief Bypass current node
     * Will call process always.
     * If you want to reduce computing cost, disconnect the node.
     * 直通当前的Node，但是还是会调用处理函数
     * 如果要减少计算量，直接断开节点的连接
     */
    void setByPass(bool);
    /**
     * @brief 获得当前bypass状态
     *
     * @return true
     * @return false
     */
    bool bypass() const;

    /**
     * @brief Processing function when bypass=true
     * bypass时调用的处理函数
     * 默认是调用原来的函数，但数据没替换
     * @param port
     * @param rc
     * @return int
     */
    virtual int processBypass(size_t port, RenderContext& rc);

    Node& operator>>(Node& rhs);

    /**
     * @brief Prepare for audio processing.
     *
     * @param config
     */
    int prepare(NodeProcessingConfig config);

protected:
    Node(const Node& other) = delete;
    Node& operator=(const Node& other) = delete;

    explicit Node(int id, AudioGraph* graph);

    virtual void setId(int id);

    /**
     * @brief 如果需要进行额外的处理，重写这个方法
     *
     * @param config
     */
    virtual int prepareEx(NodeProcessingConfig config);

    void setGraph(AudioGraph* graph);

    friend class ElasticGraphNode;
    friend class RouteNode;

    class NodeImpl;
    std::shared_ptr<NodeImpl> impl;
};

class NullNode : public Node {
public:
    NullNode() = default;
    virtual ~NullNode() = default;
    int process(int out_port_id, RenderContext& rc) override final {
        return 0;
    };

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    bool cleanUp() override final {
        return false;
    }
};

MAMMON_ENGINE_NAMESPACE_END

#endif
