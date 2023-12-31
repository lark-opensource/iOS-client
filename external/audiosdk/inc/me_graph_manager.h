//
// Created by hw on 2019-08-05.
//

#pragma once
#ifndef AUDIO_EFFECT_AE_GRAPH_MANAGER_H
#define AUDIO_EFFECT_AE_GRAPH_MANAGER_H

#include <memory>
#include <atomic>
#include "me_audiostream.h"
#include "me_graph.h"
#include "mammon_engine_defs.h"
#include "ae_effect.h"
#include "ae_extractor.h"
#include "me_file_source.h"
#include "me_stream_source_node.h"


MAMMON_ENGINE_NAMESPACE_BEGIN

class Node;
class BufferSourceNode;
class PositionalBufferSourceNode;
class MixerNode;
class SinkNode;
class AudioEffectNode;
class FileSourceNode;
class PositionalFileSourceNode;
class OscillatorNode;
class DeviceInputSourceNode;
class TriggerNode;
class NoiseNode;
class ADSRNode;
class AmbisonicBinauralDecoderNode;
class AmbisonicEncoderNode;
class AmbisonicRotatorNode;
class SamiEffectorNode;
class RecorderNode;
class ResampleNode;
class GainNode;
class MDSPNode;
class StreamSourceNode;

class ExtractorNode;

class ElasticGraphNode;
class RouteNode;
class SpatializerNode;
#ifdef BUILD_RESONANCE_AUDIO_NODE
class ResonanceNode;
#endif
#if defined(BUILD_HRTF_RENDERING)
class HrtfRenderingNode;
#endif

class ConvolverNode;
class BiquadFilterNode;

/**
 * @brief 图编辑管理器
 * 用于编辑图，背后会做一些特别的处理
 * 编辑时持有AudioGraph对象，结束编辑时减少引用AudioGraph对象
 */
class MAMMON_EXPORT GraphManager final {
public:
    GraphManager(const GraphManager&) = delete;
    GraphManager& operator=(const GraphManager&) = delete;

    GraphManager();
    ~GraphManager() = default;

    void setSourceStr(const std::string& source);

    Node* getNode(int id);
    /**
     * @brief 检查是否创建了特定节点
     *
     * @param id 检查的节点id
     * @return true
     * @return false
     */
    bool hasNode(int id);
    /**
     * @brief 删除已创建的节点
     *
     * @param id 要删除的节点id
     * @return true
     * @return false
     */
    bool deleteNode(int id);

    /**
     * @brief 获得当前托管的AudioGraph
     * 只有需要图编辑的时候才用GraphManager，其他时候最好将它的指针持有起来
     * 否则调用createNewGraph之后原来的图对象指针会减少引用
     * @return std::shared_ptr<AudioGraph>
     */
    std::shared_ptr<AudioGraph> getCurrentGraph() const {
        return graph_;
    }

    /**
     * @brief Create a New Graph and return the old one
     * 创建一个新的AudioGraph，将旧的图返回
     * @param executor 执行调度器
     * @return
     */
    std::shared_ptr<AudioGraph> createNewGraph(AudioGraphExecutor* executor = nullptr);

    /**
     * @brief Load graph from outside stream.
     * 从流里反序列化图
     * @return
     */
    int loadGraph(std::istream&);

    /**
     * @brief Save graph to outside stream
     * 向流中序列化图
     */
    void saveGraph(std::ostream&);

    /**
     * @brief 创建BufferSourceNode
     * 不带时间同步功能的buffer
     * @param data 数据源
     * @return std::shared_ptr<BufferSourceNode>
     */
    BufferSourceNode* createBufferSourceNode(const std::shared_ptr<AudioStream>& data);
    /**
     * @brief 创建SeekableSourceNode
     * 带时间同步功能的播放节点
     * @param data 数据源
     * @param position 开始播放位置
     * @return std::shared_ptr<SeekableSourceNode>
     */
    PositionalBufferSourceNode* createPositionalBufferSourceNode(const std::shared_ptr<AudioStream>& data,
                                                                 TransportTime position);
    /**
     * @brief 创建MixerNode
     * 混音器节点，将多个节点的声音混合到一起
     * @return std::shared_ptr<MixerNode>
     */
    MixerNode* createMixerNode();
    /**
     * @brief 创建SinkNode
     * 最终输出节点，一般都由IO Callback拉取
     * @return std::shared_ptr<SinkNode>
     */
    SinkNode* createSinkNode();

    /**
     * @brief 创建 AudioEffectNode，特效类从外部传入
     * @param effect 特效实例
     * @return 创建的AudioEffectNode实例的裸指针
     */
    AudioEffectNode* createAudioEffectNode(std::shared_ptr<mammon::Effect> effect);

    /**
     * @brief 创建文件流的Node, 运行时采样率与source采样率不同时自动启用重采样
     *
     * @param source 音频文件源
     * @return FileSourceNode*
     */
    FileSourceNode* createFileSourceNode(const std::shared_ptr<mammon::FileSource>& source);

    /**
     * @brief 创建文件流的Node
     *
     * @param source 音频文件源
     * @prarm enable_resample 运行时采样率与source采样率不同时自动启用重采样
     * @return FileSourceNode*
     */
    FileSourceNode* createFileSourceNode(const std::shared_ptr<mammon::FileSource>& source, bool enable_resample);


    /**
     * @brief 创建可以在特定位置触发播放的文件流Node
     *
     * @param source 音频文件源
     * @param pos 播放位置 （单位采样）
     * @return PositionalFileSourceNode*
     */
    PositionalFileSourceNode* createPositionalFileSourceNode(const std::shared_ptr<mammon::FileSource>& source,
                                                             TransportTime pos);

    /**
     * @brief Create a OscillatorNode object
     * 创建OscillatorNode发出特定波形
     * @return OscillatorNode*
     */
    OscillatorNode* createOscillatorNode();

    NoiseNode* createNoiseNode();

    ADSRNode* createADSRNode();

    AmbisonicBinauralDecoderNode* createAmbisonicBinauralDecoderNode(int order, const std::string sh_hrir_filename);

    AmbisonicEncoderNode* createAmbisonicEncoderNode(int order);
#if defined(BUILD_AMBISONIC_ROTATOR)
    AmbisonicRotatorNode* createAmbisonicRotatorNode(int order);
#endif
    /**
     * @brief Create a DeviceInputSourceNode object to record from mic
     * 创建DeviceInputSourceNode来录制mic的声音
     * @param device_id
     * @return DeviceInputSourceNode*
     */
    DeviceInputSourceNode* createDeviceInputSourceNode(size_t device_id);

    /**
     * @brief Create a TriggerNode to trigger a callback out of audio thread
     * 创建一个TriggerNode，在音频线程之外触发回调
     * @param async
     * @return TriggerNode*
     */
    TriggerNode* createTriggerNode(bool async = true);

    /**
     * @brief Create a ExtractorNode from Extractor class
     * 创建ExtractorNode来提取音频特征
     * @return ExtractorNode*
     */
    ExtractorNode* createExtractorNode(std::shared_ptr<mammon::Extractor>);

    /**
     * @brief Create a SamiEffectorNode to perform sami audio effect
     * @param effector_type @see MusicDspEffect.h
     */
    SamiEffectorNode* createSamiEffectorNode(int effector_type, size_t block_size);

    /**
     * @brief Create RecorderNode to write PCM data to file.
     * @param format Encoder format
     * @param async If data is written async
     * @return
     */
    RecorderNode* createRecorderNode(const EncoderFormat& format, bool async = true);

    ElasticGraphNode* createGraphNode(std::shared_ptr<AudioGraph> graph, RouteNode* route_node, Node* entry_node);

    SpatializerNode* createSpatializerNode(SpatializerType type);

    RouteNode* createRouteNode();

#ifdef BUILD_RESONANCE_AUDIO_NODE
    ResonanceNode* createResonanceNode(int order);
#endif

#if defined(BUILD_HRTF_RENDERING)
    HrtfRenderingNode* createHrtfRenderingNode(std::string& hrir_filename);
#endif

    ConvolverNode* createConvolverNode();

    /**
     * @brief Create a Resample Node object
     *
     * @param ratio Resampling ratio
     * @return ResampleNode*
     */
    ResampleNode* createResampleNode(float ratio);

    /**
     * @brief Create a GainNode object
     *
     * @return GainNode*
     */
    GainNode* createGainNode();

    BiquadFilterNode* createBiquadFilterNode();

    MDSPNode* createMDSPNode();

    StreamSourceNode* createStreamSourceNode();

#if SAMI_CORE_USING_FOR_DEMO
    static void setAuthResult(bool isAuthPass) {
        isAuthPass_ = isAuthPass;
    }
#endif

private:
    int generateNodeId();

private:
    std::atomic<size_t> node_count;
    std::shared_ptr<AudioGraph> graph_;

#if SAMI_CORE_USING_FOR_DEMO
    static bool isAuthPass_;
#endif

    std::string source_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_AE_GRAPH_MANAGER_H
