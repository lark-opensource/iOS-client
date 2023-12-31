//
// Created by jiamin zhang on 2021/7/2.
//

#ifndef MAMMON_AUDIO_IO_ME_MEMORY_SOURCE_H
#define MAMMON_AUDIO_IO_ME_MEMORY_SOURCE_H
#include "me_resource_stream.h"
#include "me_file_resource.h"

namespace mammon {

class MemoryResourceStream : public IResourceStream {
public:
    MemoryResourceStream(uint8_t *data, size_t size, bool deallocating_by_own = true);

    virtual ~MemoryResourceStream();

    virtual std::string name() override;

    virtual size_t read(uint8_t *buf, size_t size) override;

    virtual int seek(off_t pos, int mode) override;

    virtual size_t tell() override;

    virtual size_t length() override;

    virtual void close() override;
private:
    uint8_t *data_ = nullptr;
    size_t size_ = 0;
    size_t read_pos_ = 0;
    bool deallocating_by_own_;
};

}


#endif  // MAMMON_AUDIO_IO_ME_MEMORY_SOURCE_H
