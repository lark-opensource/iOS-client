
//
// Created by William.Hua on 2020/11/19.
//

#pragma once

#include <memory>
#include <string>
#include <atomic>
#include <array>
#include <functional>
#include <future>
#include <vector>

namespace mammon
{
class SentenceScoreDetector {
public:
    class SpeechDataBuffer{
    public:
        int64_t getSize() const;
        int64_t getCapacity() const;
        int pushInput(const float* input_data, int input_size);
        const float* getData() const;
        void clear();
    private:
        constexpr static int kBufferCapacity{96000};
        int64_t size_{0};                             // how many data in this buffer;
        std::array<float, kBufferCapacity> buffer_{0};   // init with 64000 = 16000 * 4
    };

    SentenceScoreDetector();

    int loadModel(const char* model_buffer, int buffer_len);

    int loadRefFeature(const char* ref_feature_data, int data_len);

    const std::vector<float>& getRefFeature() const;

    bool isStartedTalking() const;

    void startTalking();

    void finishTalking();

    const SpeechDataBuffer& getSpeechDataBuffer() const;

    using ScoreCallback = std::function<void(void*, float)>;
    void setScoreCallback(ScoreCallback f, void* listener);

    const ScoreCallback& getScoreCallback() const;

    float calcScore();

    int pushInput(const float* input_data, int input_size);

private:
    class Impl;
    std::shared_ptr<Impl> impl_;
};

}
