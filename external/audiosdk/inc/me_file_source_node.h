#pragma once
#ifndef _MAMMON_AE_FILE_SOURCE_NODE_
#define _MAMMON_AE_FILE_SOURCE_NODE_

#include <atomic>
#include <cmath>
#include <limits>
#include "me_file_source.h"
#include "me_node.h"
#include "me_source_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 从文件读流的节点
 * 这个Source Node是和transport时间无关的类，激活播放默认就从0开始
 * 后面不cleanup 就继续递增读位置，如果超过就返回0或空
 */
class MAMMON_EXPORT FileSourceNode : public Node, public SourceNode {
public:
    static std::shared_ptr<FileSourceNode> create(std::shared_ptr<mammon::FileSource> source) {
        std::shared_ptr<FileSourceNode> node = std::shared_ptr<FileSourceNode>(new FileSourceNode(std::move(source), true));
        node->addOutput();
        return node;
    }

    static std::shared_ptr<FileSourceNode> create(std::shared_ptr<mammon::FileSource> source, bool enable_resample) {
        std::shared_ptr<FileSourceNode> node = std::shared_ptr<FileSourceNode>(new FileSourceNode(std::move(source), enable_resample));
        node->addOutput();
        return node;
    }

    virtual ~FileSourceNode();

    audiograph::NodeType type() const override {
        return audiograph::NodeType::FileSourceNode;
    }

    int process(int port, RenderContext& rc) override;

    /**
     * @brief 设置文件输入源
     *
     * @param source 文件输入源
     */
    void setSource(std::shared_ptr<mammon::FileSource> source);

    mammon::FileSource* getSource() const;

    /**
     * @brief 获取当前loop状态
     *
     */
    bool getLoop() const override;
    /**
     * @brief 设置loop状态
     * @param b 是否loop
     */
    void setLoop(bool b) override;

    void start() override;

    void stop() override;

    void pause() override;

    bool cleanUp() override;


    void setState(TransportState state);

    /**
     * @brief returns current state @see TransportState
     * @return
     */
    TransportState state();

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    /**
     * returns the count of loop
     * it reset to zero if stop()/setLoop(false) has been call
     */
    int32_t getLoopCount() const;

    /**
     * returns the progress of playback, in the range of [0, 1]
     */
    float getProgress();

    /**
     * set the playback start position
     * The default start position is 0, and it will be set to (source->getNumFrames() - 1) if clip_index out of the audio file range
     * @param clip_index, the sample index of the audio
     * @return true if success, others false
     */
    bool setClipStartSampleIndex(size_t clip_index);

    /**
     * set the playback stop position
     * The default start position is (source->getNumFrames() - 1), and it will be set to (source->getNumFrames() - 1) if clip_index out of the audio file range
     * @param clip_index, the sample index of the audio
     * @return true if success, others false
     */
    bool setClipEndSampleIndex(size_t clip_index);

    /**
     * set the playback start time
     * @param clip_time, the time(in seconds) you want to start
     * @return true if success, others false
     */
    bool setClipStartTime(float clip_time);

    /**
     * set the playback end time
     * @param clip_time , the time(in seconds) you want to end
     * @return true if success, others false
     */
    bool setClipEndTime(float clip_time);

    float getClipStartTime() const;
    float getClipEndTime() const;
    size_t getClipStartSampleIndex() const;
    size_t getClipEndSampleIndex() const;

    /**
     * set the position in the track
     */
    void setPosition(TransportTime pos);
    TransportTime getPosition() const;

protected:
    explicit FileSourceNode(std::shared_ptr<mammon::FileSource> source, bool enable_resample = true);

    class Impl;
    std::shared_ptr<Impl> impl_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif