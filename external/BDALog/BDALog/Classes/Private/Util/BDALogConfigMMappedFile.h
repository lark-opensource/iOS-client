//
//  BDALogConfigMMappedFile.hpp
//  BDALog
//
//  Created by liuhan on 2023/3/2.
//

#ifndef BDALogConfigMMappedFile_h
#define BDALogConfigMMappedFile_h

#include <stdio.h>
#include "BDMMappedFile.h"
namespace BDALog {

class BDALogConfigMMappedFile : public BDMMappedFile {
    
public:
    BDALogConfigMMappedFile(size_t file_size);
    ~BDALogConfigMMappedFile() = default;
    
    bool WriteRecordAndLength(const char *record, int32_t record_len, int32_t file_offset);
    
    bool WriteStorageConfig(int32_t index, std::string& instance_name, bool is_free, int64_t max_size, int32_t expire_time, std::string& prefix, std::string& suffix);
    void GetStorageConfig(int32_t index, std::string& instance_name, bool& is_free, int64_t& max_size, int32_t& expire_time, std::string& prefix,  std::string& suffix);
    
    bool WriteISFree(int32_t index, bool is_free);
    
    bool WriteInstanceName(int32_t index, std::string& instance_name);
    
    bool WriteMaxSize(int32_t index, int64_t max_size);
    
    bool WriteExpireTime(int32_t index, int32_t expire_time);
    
    bool WritePrefix(int32_t index, std::string& prefix);
    
    bool WriteSuffix(int32_t index, std::string& suffix);
    
    std::string GetFileData(int32_t file_offset, int32_t file_len);
    
    
    bool WriteBlockCount(int32_t block_count);
    int32_t GetBlockCount();
    
    bool CheckFileSize(int required_len, int32_t file_offset);
};

}
#endif /* BDALogConfigMMappedFile_h */
