#pragma once

#include <cstddef>
#include <tuple>
#include <memory>
#include <vector>
#include <map>
#include <functional>
#include <mutex>
#include "me_audiograph_executor.h"
#include "mammon_engine_defs.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

class Node;
class SinkNode;
class DeviceInputSourceNode;

/**
 * @brief 代表AudioGraph中一条信号路径
 * 这个三元组的三个值分别表示：输出Node ID, 输出Port, 输入Port
 * 开始节点用map中的key表示
 */
using NodeID = size_t;
using PortID = size_t;
using SignalPath = std::tuple<NodeID, PortID, PortID>;

/**
 * @brief 存放整个信号图的数据结构
 * 这个图结构除了存储了整个图连接的拓扑情况外，还包含了图执行相关的信息
 */
class MAMMON_EXPORT AudioGraph {
public:
    AudioGraph();
    ~AudioGraph();

    /**
     * @brief 增加一个节点
     * 不需要被调用，createXXNode的时候自动添加
     * @param node
     */
    void addNode(std::shared_ptr<Node> node);
    void addNode(std::shared_ptr<SinkNode> node);
    void addNode(std::shared_ptr<DeviceInputSourceNode> node);

    /**
     * @brief Prepare for audio processing.
     *
     * @param sample_rate The intended process sample rate
     * @param max_block_samples The maximum number of samples that could ever
     * be requested with pull(). Pulling more samples than this will throw
     * an error.
     */
    int prepare(size_t sample_rate, size_t max_block_size);

    // void addSink(std::shared_ptr<SinkNode> node);
    // void addDeviceInput(std::shared_ptr<DeviceInputSourceNode> node);
    /**
     * @brief
     *
     * @param node
     */
    bool deleteNode(Node* node);
    /**
     * @brief
     *
     * @param id
     */
    bool deleteNode(NodeID id);
    /**
     * @brief Get the Node object
     *
     * @param id
     * @return Node*
     */
    Node* getNode(NodeID id);
    /**
     * @brief
     *
     * @param id
     * @return true
     * @return false
     */
    bool hasNode(NodeID id);

    /**
     * @brief 添加一条信号路径的边
     * 不需要调用，connect时自动
     * @param path
     * @param dest_node
     */
    void addEdge(SignalPath&& path, NodeID dest_node);
    /**
     * @brief 删除一条信号路径的边
     * 不需要调用，disconnect的时候自动
     * @param path
     * @param dest_node
     */
    void deleteEdge(SignalPath&& path, NodeID dest_node);
    /**
     * @brief 检查Node间是不是有连接
     *
     * @param dst_node 目的Node ID
     * @param src_node 源Node ID
     * @return true
     * @return false
     */
    bool hasPath(NodeID src_node, NodeID dst_node);
    /**
     * @brief 检查是不是存在一个信号路径
     *
     * @param path 路径
     * @param dest_node 目的Node ID
     * @return true
     * @return false
     */
    bool hasEdge(SignalPath&& path, NodeID dest_node);

    /**
     * @brief 深度遍历图
     *
     * @param src_node 源节点ID
     * @param visitor 访问函数
     */
    void DFSVisit(NodeID src_node, std::function<void(Node*)>&& visitor);

    /**
     * @brief Get the Executor object
     *
     * @return AudioGraphExecutor*
     */
    AudioGraphExecutor* getExecutor();
    /**
     * @brief Set the Executor object
     *
     * @param executor
     */
    void setExecutor(std::unique_ptr<AudioGraphExecutor> executor);

    /**
     * @brief Global lock for operating graph
     *
     */
    std::mutex graphLock;

    std::string toString();

    SinkNode* getSinkNode() const {
        return sink_;
    }

    const std::map<size_t, DeviceInputSourceNode*>& getDeviceInputNodes() const {
        return device_sources_;
    }

private:
    std::unique_ptr<ErrorRecords> node_errors_;
    std::unique_ptr<AudioGraphExecutor> executor_;
    std::vector<std::shared_ptr<Node>> nodes_;
    std::map<size_t, std::vector<SignalPath>> paths_;
    SinkNode* sink_;
    std::map<size_t, DeviceInputSourceNode*> device_sources_;

    friend class GraphManager;
};

MAMMON_ENGINE_NAMESPACE_END
