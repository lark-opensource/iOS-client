//
// Created by william on 2020/1/6.
//
#pragma once

#include "mammon_engine_defs.h"
#include "me_file_source.h"
#include <vector>
namespace mammon
{

/**
 * @brief 文件缓存支持类
 * 
 */
class MAMMON_EXPORT FileSourceCache : public FileSource 
{
public:
    class Cache
    {
    public:
        explicit Cache(size_t cache_size)
            : cache_size_(cache_size)
        {
        }

        virtual ~Cache() = default;
        /**
         * Fills cache as much as possible
         * @param source read data from source to fill cache
         */
        virtual void fillCache(const std::shared_ptr<FileSource>& source) = 0;

        /**
         * Reads data from cache, returns the number of sample has read.
         *
         */
        virtual int readFromCache(float* buffer, size_t num_samples_to_read) = 0;

        /**
         * returns the number of available samples in cache
         */
        virtual size_t getAvailableSize() const = 0;

        /**
         * returns the cache size.
         */
        virtual size_t getCacheBufferSize() const = 0;

        /**
         * Discards some samples
         */
        virtual void skip(size_t num_sample_skip) = 0;

        /**
         * clears cache and getAvailableSize() will return zero after clear.
         */
        virtual void clear() = 0;

    protected:
        /**
        * read data from source returns number of frames has readed
        */
        size_t readDataFromSource(const std::shared_ptr<FileSource>& source)
        {
            const size_t num_sample_to_fill = getCacheBufferSize() - getAvailableSize();
            if(internal_buffer_.size() < num_sample_to_fill) { internal_buffer_.resize(num_sample_to_fill); }

            return source->read(internal_buffer_.data(), num_sample_to_fill / source->getNumChannel());
        }

    protected:
        size_t cache_size_;
        std::vector<float> internal_buffer_;
    };
public:
    explicit FileSourceCache(std::shared_ptr<FileSource> source);

    explicit FileSourceCache(std::shared_ptr<FileSource> source, size_t cache_size);

    ~FileSourceCache() override;

    /**
     * Returns the cache buffer size.
     */
    size_t getCacheBufferSize() noexcept;

    /**
     * Returns the available size of data in cache.
     */
    size_t getAvailableSize();

    bool seek(size_t new_position) override;

    size_t read(float *buffer, size_t frame_num) override;

    size_t getNumChannel() const override ;
    size_t getSampleRate() const override ;
    size_t getNumFrames() const override ;
    size_t getNumBit() const override ;
    size_t getPosition() override ;

    /**
     * wait until decode thread fill the cache buffer
     *
     * this method is also using for synchronizing FileSource state,
     * if you want testing the FileSource state after read or seek, it will be usefull.
     */
    void waitUntilDecodeCompleted();

    constexpr static size_t kDefaultCacheSize = 32768;
    constexpr static size_t kDefaultNumDecodeThread = 1;
private:
    /**
     * Fills the cache buffer as much as possible
     */
    void fillCacheBuffer();

    /**
     * Reads sample from cache and returns the acctual read number of frames.
     * The size of buffer at least is frame_num * num_channel.
     */
    int readFromCacheOrSource(float* buffer, size_t frame_num);

    /**
     * Discards some data in cache
     * @param new_position
     */
    void skipFramesInCache(size_t new_position);

    /**
     * Clears cache buffer
     */
    void clearCache();

    /**
     * Resets file source position
     */
    void resetSourcePosition(size_t new_position);

    /**
     * Returns true if seek position out of cache range
     */
    bool isSeekDistanceOutOfCacheRange(size_t new_pos);

    /**
     * Returns true if seek position in the range of cache
     */
    bool isSeekPositionInCacheRange(size_t new_pos);

    /**
     * Returns true if seek back
     */
    bool isSeekBack(size_t new_pos);

private:
    class Impl;
    std::shared_ptr<Impl> impl_;
};
}
