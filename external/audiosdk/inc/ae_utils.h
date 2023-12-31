#include <cstdint>

namespace mammon {
    /*
     * Convert an array of floats to and array of 16-bit integers.
     *
     *  @param source: input array
     *  @param destination: output array
     *  @param num_samples: number of value to convert
     */
    int convertFloatToPcm16(const float* source, int16_t* destination, int num_samples);

    /*
     * Convert an array of 16-bit integers to and array of floats.
     *
     *  @param source: input array
     *  @param destination: output array
     *  @param num_samples: number of value to convert
     */
    int convertPcm16ToFloat(const int16_t* source, float* destination, int num_samples);

    /*
     * Deinterleave an array of 16-bit integers
     *
     * @param source: input array L-R-L-R-...-L-R
     * @param destination: output array: L-L-...-L, R-R-...-R
     * @param num_samples: number of value per channel
     * @param channels: number of channels
     */
    int deinterleavePcm16(const int16_t* source, int16_t** destination, int num_samples, int channels);

    /*
     * Interleave an array of 16-bit integers
     *
     * @param source: input array: L-L-...-L, R-R-...-R
     * @param destination: output array: L-R-L-R-...-L-R
     * @param num_samples: number of value per channel
     * @param channels: number of channels
     */
    int interleavePcm16(const int16_t** source, int16_t* destination, int num_samples, int channels);

    /*
     * Deinterleave an array of floats
     *
     * @param source: input array L-R-L-R-...-L-R
     * @param destination: output array: L-L-...-L, R-R-...-R
     * @param num_samples: number of value per channel
     * @param channels: number of channels
     */
    int deinterleaveFloat(const float* source, float** destination, int num_samples, int channels);

    /*
     * Interleave an array of floats
     *
     * @param source: input array: L-L-...-L, R-R-...-R
     * @param destination: output array: L-R-L-R-...-L-R
     * @param num_samples: number of value per channel
     * @param channels: number of channels
     */
    int interleaveFloat(const float** source, float* destination, int num_samples, int channels);
}  // namespace mammon