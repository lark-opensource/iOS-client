#pragma once

#include <memory>
#include <vector>
#include <functional>
#include <mutex>
#include "me_track.h"
#include "me_io_manager.h"
#include "me_transport.h"
#include "me_graph_manager.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 引擎系统对象
 * 全局只存在一份实例
 */
class MAMMON_EXPORT AudioEngine final {
public:
    /**
     * @brief Construct a new Audio Engine object
     *
     * @param block_size 算法处理的基本块大小
     * @param sr 系统采样率（假设系统的输入和输出采样率一致）
     */
    AudioEngine(size_t block_size, size_t sr = 44100);

    ~AudioEngine();

    /**
     * @brief Get the Graph Manager object
     *
     * @return GraphManager&
     */
    GraphManager& getGraphManager() {
        return *graph_manager_;
    };

    /**
     * @brief Get the Transport object
     *
     * @return Transport&
     */
    Transport& getTransport() {
        return *transport_;
    };
    /**
     * @brief
     *
     * @return IOManager&
     */
    IOManager& getIOManager() {
        return *io_manager_;
    };

    /**
     * @brief 创建一个轨道对象
     *
     * @param track_type 轨道类型（目前只有音频轨）
     * @return Track& 新创建的轨道引用
     */
    Track& createTrack(TrackType track_type);
    /**
     * @brief 删除轨道
     *
     * @return true
     * @return false
     */
    bool deleteTrack(Track*);

    /**
     * @brief 获取当前引擎采样率
     *
     * @return size_t
     */
    size_t getSampleRate() const {
        return sample_rate_;
    };
    /**
     * @brief 设置引擎采样率
     *
     * @param sr 新采样率
     */
    void setSampleRate(size_t sr);

    /**
     * @brief 获取内部节点处理block大小
     * 一般block越小，系统延迟越低，但需要消耗更多的CPU
     * @return size_t
     */
    size_t getBlockSize() const {
        return block_size_;
    };
    /**
     * @brief 设置内部节点的block大小
     * 一般block越小，系统延迟越低，但需要消耗更多的CPU
     * block大小一般都是2的幂，比如128/512/1024/4096等
     * @param block_size block大小
     */
    void setBlockSize(size_t block_size);

    /**
     * @brief 遍历系统内的轨道
     * 需要获取全局锁才能操作
     * @param fn 遍历操作的函数
     */
    void walk(std::function<void(Track&)>&& fn);

    /**
     * @brief 获取全局锁对象
     * 目前只提供全局锁才能操作业务对象如：Track、Clip
     * @return std::mutex&
     */
    std::mutex& getGlobalLock() {
        return global_lock_;
    };

    size_t getDestNodeId() const {
        return dest_node_id_;
    };

    /**
     * @brief 启动引擎运行
     * 没有启动前，没法让IOManager准备好线程做预先计算
     * @return true
     * @return false
     */
    bool start();
    /**
     * @brief 停止引擎工作
     * 停止IOManager线程，不向输出缓冲区里写数据
     * @return true
     * @return false
     */
    bool stop();

private:
    std::vector<std::unique_ptr<Track>> tracks_;
    size_t sample_rate_;
    size_t block_size_;

    size_t dest_node_id_;

    std::mutex global_lock_;

    std::unique_ptr<GraphManager> graph_manager_;
    std::unique_ptr<Transport> transport_;
    std::unique_ptr<IOManager> io_manager_;
};

MAMMON_ENGINE_NAMESPACE_END
