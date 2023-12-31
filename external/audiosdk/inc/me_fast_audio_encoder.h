
//
// Created by William.Hua on 2021/3/28.
//

#pragma once
#include "me_audio_encoder.h"
#include <vector>
namespace mammon
{
class FastAudioEncoder : public AudioEncoder
{
public:
    /**
     * initialization with number of workers, but the real creation of workers happens in open()
     * so before you call open(), the getNumberWorkers() still returns 0.
     *
     * if num_workers is <= 0, it will use the std::thread::hardware_concurrency() as default
     * if num_workers is too large, it will use the std::thread::hardware_concurrency() as default
     */
    explicit FastAudioEncoder(int num_workers);
    virtual ~FastAudioEncoder() = default;

    /**
    * open output file to write, also launch multiple threads(workers) for fast encoding.
    *
    * the number of threads is set in the constructor.
    *
    * @return 0 if success, others failed
    */
    int open(const std::string &output_path, int sample_rate, int num_channels, int64_t bit_rate) noexcept override = 0;

    /**
     * write data to internal buffer and then signal workers to encoding them
     *
     * @return the number of bytes written to output,
     *         maybe 0 because the worker which in other thread not finished encoding.
     */
    int64_t writePlanarData(const float *const *planar_data,
                            int num_channels,
                            int64_t num_sample_per_channel) noexcept override = 0;

    /**
     * write data to internal buffer and then signal workers to encoding them
     *
     * @return the number of bytes written to output,
     *         maybe 0 because the worker which in other thread not finished encoding.
     */
    int64_t writeInterleaveData(const float *interleave_data,
                                int num_channels,
                                int64_t num_sample_per_channel) noexcept override = 0;

    /**
     * return the initialization number of workers.
     *
     * this the number is a reference when create workers.
     */
    int getInitNumberWorkers() const noexcept;


    /**
     * return the number of actual workers which created when call open()
     */
    virtual int getNumberWorkers() const noexcept = 0;

protected:
    /**
     * encode internal frames buffer
     *
     * @param flush, flush remaining data to encoding or not
     * @return the number of bytes actually encoded
     */
    virtual int encodeFrames(bool flush) = 0;

    /**
     * rearrange the incoming encoded packet and write them to somewhere
     *
     * @param packets, a array of packets that contains encoded bytes
     * @param packetSizes, a array of packet's size,
     * @param first, first packet or not
     * @return the number of bytes actually encoded
     */
    virtual int processPackets(const std::vector<uint8_t>& packets, const std::vector<int>& packetSizes, bool first) = 0;

private:
    int num_init_workers_{0};
};
}
