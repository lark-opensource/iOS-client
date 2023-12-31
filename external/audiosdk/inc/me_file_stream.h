#pragma once

#include "me_resource_stream.h"

namespace mammon {

    class FileStream final : public IResourceStream {
    private:
        FILE *fp_;
        std::string path_;
        uint32_t length_ = 0;

    public:
        explicit FileStream(const std::string path);

        std::string name() override;

        bool isOpen() const;

        size_t read(uint8_t *buf, size_t size) override;

        int seek(off_t pos, int mode) override;

        size_t tell() override;

        void close() override;

        size_t length() override;

        ~FileStream() final;
    };

}