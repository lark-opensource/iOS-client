//
//  semi_mmap_file.hpp
//  Hermas
//
//  Created by liuhan on 2022/6/14.
//

#ifndef semi_mmap_file_hpp
#define semi_mmap_file_hpp

#include "env.h"
#include "file_path.h"
#include "mmap_file.h"
#include "file_fragment.h"
#include "semifinished_helper.h"

#include <string.h>
#include <unordered_map>


namespace hermas {

class ModuleEnv;

class SemiMmapFile {
public:
    SemiMmapFile(const FilePath& file_path);
    ~SemiMmapFile() = default;
    
public:
    bool CreatSemiFile();
    bool OpenSemiFile();
    void CloseSemiFile();
    void FreeSemiFile();
    
    bool WriteSemiRecord(const std::string& record, const std::string& traceID, const std::string& spanID, bool isTrace);
    
    std::string ReadAndDeleteSemiRecord(const std::string& recordID, bool isTrace);
    
    bool DeleteSemiRecord(const std::string& recordID, bool isTrace);
    
public:
    bool ReadBlockIsUse(int32_t fileOffset);
    int32_t ReadBlockLen(int32_t fileOffset);
    std::string ReadSemiRecord(int32_t fileOffset, int32_t length);
    std::string ReadSemiTraceID(int32_t fileOffset);
    bool DeleteSemiRecord(int32_t fileOffset);

private:
    bool DeleteSemiRecord(const std::string& recordID, char *addr);
    char* FindInSemiMap(const std::string& recordID, bool isTrace);

public:
    FilePath const m_file_path;
    int m_file_len; //文件总大小
    FILE_HANDLE m_fd;
private:
    char *mp_mmap_file; //文件起始地址
    std::unordered_map<std::string, char *> m_recordID_addr_map;
    std::unique_ptr<MemoryAllocator> m_memory_allcator;
    
};
}

#endif /* semi_mmap_file_hpp */
