//
//  BDEncryptor.h
//  BDALog
//
//  Created by kilroy on 2021/10/26.
//

#ifndef BDEncryptor_h
#define BDEncryptor_h

#include <stdint.h>
#include <string>

#include "BDALogBufferBlock.h"

namespace BDALog {

class BDEncryptor final {
  public:
    BDEncryptor(const std::string& public_key);
    ~BDEncryptor() = default;
    
    BDEncryptor(const BDEncryptor&) = delete;
    BDEncryptor& operator=(const BDEncryptor&) = delete;
    
    void SetHeaderInfo(char* _data, bool _is_async);
    bool CryptSyncLog(const char* const log, size_t input_len, char* final_log);
    bool CryptAsyncLog(const char* const _log_data, size_t _input_len, BDALogBufferBlock& _out_buff, size_t& _remain_nocrypt_len);
    
    static bool GetLogLenInBuffer(char* data, size_t data_len, bool& out_is_async, uint32_t& out_raw_log_len);
    
    static void SetTailerInfo(char* out_data);
    //解析_data中header的第一条log写入时间
    static std::string GetFirstLogDate(const void* data);
    static uint32_t GetHeaderLen();
    static uint32_t GetTailerLen();
    static void UpdateLogHour(char* data);
    static uint32_t GetLogLen(const char* const data, size_t _len);
    static void UpdateLogLen(char* data, uint32_t add_len);
    
private: 
    uint32_t tea_key_[4];
    char client_pubkey_[64];
    char log_path_[4];
};

} //namespace BDALog
#endif /* BDEncryptor_h */
