#ifndef MAMMONSDK_MAMMON_ENGINE_TYPE_DEFS_H
#define MAMMONSDK_MAMMON_ENGINE_TYPE_DEFS_H

#include "mammon_engine_defs.h"
#include <cstdint>
#include <array>

MAMMON_ENGINE_NAMESPACE_BEGIN

using Tick = std::int64_t;
using Second = double;
using MilliSecond = double;
using BPM = float;
using PPQ = std::uint32_t;
using TransportTime = std::int64_t;

constexpr PPQ DEFAULT_PPQ = 768;

using AudioFrame = std::array<float, 2>;
using AudioFrame2C = std::array<float, 2>;
using AudioFrame3C = std::array<float, 3>;
using AudioFrame4C = std::array<float, 4>;

enum class EncoderFileFormat { kWave };

struct EncoderFormat {
    EncoderFileFormat format;
};

namespace audiograph {
/**
 * @brief Node Type for a node
 * @attention 添加新类型，一定要在尾部添加，防止类型数值错乱
 */
enum class NodeType {
    AudioNode = 0,
    AudioEffectNode,
    BufferSourceNode,
    DeviceInputSourceNode,
    ExtractorNode,
    FileSourceNode,
    MixerNode,
    NoiseNode,
    OscillatorNode,
    PositionalFileSourceNode,
    PositionalBufferSourceNode,
    SinkNode,
    TriggerNode,
    ADSRNode,
    AmbisonicBinauralDecoderNode,
    AmbisonicEncoderNode,
    RecorderNode,
    GainNode,
    SamiEffectorNode,
    ResampleNode,
    GraphNode,
    RouteNode,
    SpatializerNode,
    AmbisonicRotatorNode,
    ResonanceNode,
    HrtfRenderingNode,
    ConvolverNode,
    BiquadFilterNode,
    MDSPNode,
    StreamSourceNode,
};
}  // namespace audiograph

enum class SpatializerType {
    AmbisonicFirstOrder = 0,
    AmbisonicSecondOrder,
    AmbisonicThirdOrder,
    AmbisonicFirstOrderEncoder,
    AmbisonicSecondOrderEncoder,
    AmbisonicThirdOrderEncoder,
    AmbisonicFirstOrderDecoder,
    AmbisonicSecondOrderDecoder,
    AmbisonicThirdOrderDecoder,
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // MAMMONSDK_MAMMON_ENGINE_TYPE_DEFS_H
