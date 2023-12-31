//
//  BDALogBuffer.h
//  BDALog
//
//  Created by kilroy on 2021/10/26.
//

#ifndef BDALogBuffer_h
#define BDALogBuffer_h

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <mutex>
#include <future>

#include "BDALogBufferBlock.h"
#include "BDEncryptor.h"
#include "BDContainer.hpp"
#include "BDMMappedFile.h"
#include "BDCompressor.hpp"

namespace BDALog {

enum class BDALogBufferMode {
    kSafeMode, //先压缩加密再写入mmap
    kTemporaryMode, //从默认加密迁移到自定义加密
};

//和mmap文件，管理压缩加密等事宜
class BDALogBuffer {
  public:
    BDALogBuffer(void* instance_ptr,
                 BDALogBufferMode mode,
                 const size_t buffer_size,
                 const std::string& buffer_path,
                 const std::string& public_key);
    ~BDALogBuffer();

    // 将len长度的data数据写入Buffer中，并告知外部是否需要require_flush
    bool Write(const void* data, size_t len, size_t max_len, bool &require_flush);
    // flush当前的buffer至block中
    BDALogBufferBlock ExternalFlush();
    // 生成alog内部需要写入的Log日志
    bool SyncEncryptLog(const char* log, size_t input_len, char* final_log);
    
  private:
    bool Reset();
    BDALogBufferBlock InternalFlush();
    void RealFlush(BDALogBufferBlock& block);
    void Clear();
    void ModifyBufferPosAndLenByContent();
    
    std::future<void> lazy_load_;
    // used for thread safety
    bool is_closed_;
    BDALogBufferMode mode_;
    //for saving data
    std::unique_ptr<BDMMappedFile> mmap_file_;
    BDContainer buffer_;
    size_t buffer_size_ = 0;
    std::mutex buffer_mutex_;
    //for encryption
    std::unique_ptr<BDEncryptor> log_encryptor_;
    size_t remain_no_crypt_len_;
    //for compression
    std::unique_ptr<BDCompressor> log_compressor_;
};

}


#endif /* BDALogBuffer_h */
