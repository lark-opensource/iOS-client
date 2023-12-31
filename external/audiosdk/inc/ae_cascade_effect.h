//
// Created by chenyuezhao on 2019-05-19.
//

#pragma once

#include <mutex>
#include "ae_effect.h"

namespace mammon {
    class CmdParameters;
    class MAMMON_EXPORT CascadeEffect : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "cascade";

        CascadeEffect() = default;
        CascadeEffect(int sample_rate, int num_channel);
        CascadeEffect(const std::vector<Effect*>& effects_, int channels_, int sample_rate_);
        virtual ~CascadeEffect();

        virtual int process(std::vector<Bus>& bus_array) override;
        virtual void setPreprocessing(bool on) override;

        size_t getLatency() const override;

        virtual bool needsPreprocess() override;

    private:
        std::vector<std::shared_ptr<Effect>> effects_;
        std::vector<bool> bypassed_;

        class Impl;
        std::shared_ptr<Impl> impl_;

    public:
        virtual void setParameterFromChunk(const void* chunk, int32_t size);
        void setParameterFromFile(const char* filename);
        void setParameterFromString(const char* effect_yaml_txt);
        void setParameterFromParametersArray(std::vector<CmdParameters>);
        const void* getParameterAsChunk(int32_t* size);

        // CascadeEffect无参数需要读取/设置

        // 一次重置每个effect
        void reset() override;

        // 任意大小均OK，因为所有Effect的process支持任意大小输入
        virtual size_t getRequiredBlockSize() const override {
            return 0;
        }

        int getNumberOfEffects() const;
        void add(const std::shared_ptr<Effect>& effect);
        void add(std::unique_ptr<Effect>& effect);
        void remove(int index);
        std::shared_ptr<Effect> getEffect(int index) const;
        const char* getName() const override;

        void setBypassed(int index, bool bypassed);
        bool getBypassed(int index) const;

        void release();

        bool seek(double newPosInSec, int mode = SEEK_SET) override;
        bool seek(int64_t newPosInSamples, int mode = SEEK_SET) override;
        void seekDefinitely(int64_t newPosInSamples) override;

        int latency;  // = sum of all effects's latencies

    private:
        int channels_;
        int sample_rate_;
        void* data_as_chunk_;
        size_t chunk_size_;

        std::mutex mt_;
    };
}  // namespace mammon
