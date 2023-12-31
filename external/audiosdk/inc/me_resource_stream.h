#pragma once

#include "mammon_audio_io_defs.h"
#include <string>

// Seek modes:
#define MAMMON_IRESOURCESTREAM_SEEK_BEG 0
#define MAMMON_IRESOURCESTREAM_SEEK_CUR 1
#define MAMMON_IRESOURCESTREAM_SEEK_END 2

namespace mammon {

    class IResourceStream {
    public:
        /**
         * Read stream name
         * @return name
         */
        virtual std::string name() = 0;

        /**
         * Read data from stream
         * @param buf The destination of read
         * @param size The size of buf in bytes
         * @return Actual read size
         */
        virtual size_t read(uint8_t *buf, size_t size) = 0;

        /**
         * @brief Seek the stream
         *
         * @param pos forward size
         * @param mode Seek mode is the same as fseek
         * @return <0 means failed
         */
        virtual int seek(off_t pos, int mode) = 0;

        /**
         * Return the position of reading cursor
         * @return size of the stream in bytes
         */
        virtual size_t tell() = 0;

        virtual size_t length() = 0;

        /**
         * Close the stream
         * Attention: the user who invoked open must close the stream
         * 调用open的使用者必须调用close释放资源
         */
        virtual void close() = 0;

        virtual ~IResourceStream() = default;
    };
}