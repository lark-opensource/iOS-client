//
// Created by william on 2019-05-08.
//

#pragma once
#include <vector>
#include "ae_math_utils.h"
#include "print2log.h"

namespace mammon {

    template <typename T>
    class MAMMON_EXPORT RingBufferX {
    public:
        RingBufferX(uint32_t buffer_size = 1024) {
            resize(buffer_size);
        }

        void read(std::vector<T>& dest_buffer) {
            // TODO: 用copy替代循环
            for(size_t count = 0; !isEmpty() && count < dest_buffer.size(); ++count) dest_buffer[count] = readOne();
        }

        template <typename OutputIt>
        size_t read(OutputIt start, size_t count) {
            size_t s = 0;
            for(; s < count; s++) {
                if(isEmpty()) break;
                *start++ = readOne();
            }

            return s;
        }

        void write(const std::vector<T>& input_buffer) {
            // TODO: 用copy替代循环
            for(auto& item : input_buffer) writeOne(item);
        }

        template <typename InputIt>
        void write(InputIt first, InputIt last) {
            for(; first != last; first++) { writeOne(*first); }
        }
        template <typename InputIt>
        void write(InputIt first, size_t size) {
            for(; size--; first++) { writeOne(*first); }
        }

        void writeOne(const T& x) {
            buffer_[write_ & (buffer_size_ - 1)] = x;
            if(isFull()) read_ = increase(read_);
            write_ = increase(write_);
        }

        T readOne() {
            if(isEmpty()) return T(0);
            T x = buffer_[read_ & (buffer_size_ - 1)];
            read_ = increase(read_);
            return x;
        }

        void skip(size_t num) {
            while(!isEmpty() && num-- > 0) { readOne(); }
        }

        /**
         * clear all elements then getAvailableSize() will return 0
         */
        void clear() {
            skip(getAvailableSize());
        }

        bool isEmpty() {
            return read_ == write_;
        }
        bool isFull() {
            return write_ == (read_ ^ buffer_size_);  // Eq: write ==(read + buffer_size)
        }

        void resize(uint32_t buffer_size) {
            auto pow2size = MathUtils::isPowerOf2(buffer_size)
                                ? buffer_size
                                : MathUtils::getNextNearsetPowerTwo4uint32_t(buffer_size);
            if(pow2size > max_size_) {
                printfW("ringbuffer size is too large, use the max_size as size.");
                pow2size = max_size_;
            }

            buffer_size_ = pow2size;
            buffer_.resize(buffer_size_);
        }

        uint32_t getAvailableSize() const {
            if(write_ >= read_) return write_ - read_;

            return buffer_size_ - (read_ & (buffer_size_ - 1)) + (write_ & (buffer_size_ - 1));
        }

        uint32_t getSize() const {
            return buffer_size_;
        }

        uint32_t getMaxSize() const {
            return max_size_;
        }

    private:
        uint32_t read_ = {0};
        uint32_t write_ = {0};
        uint32_t buffer_size_ = {0};
        const static uint32_t max_size_ = {1 << 16};
        std::vector<T> buffer_;

    private:
        uint32_t increase(int p) {
            return (p + 1) & (2 * buffer_size_ - 1);  // mod(2*buffer_size, p+1);
        }
    };

}  // namespace mammon
