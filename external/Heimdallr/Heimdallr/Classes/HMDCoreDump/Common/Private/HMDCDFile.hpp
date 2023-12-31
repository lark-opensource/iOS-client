//
//  HMDCDFile.hpp
//  AWECloudCommand
//
//  Created by maniackk on 2020/10/13.
//

#ifndef HMDCDFile_hpp
#define HMDCDFile_hpp

#include <stdio.h>

class CDFile {
    const char * m_path;
    
    int m_fd;
    
    size_t m_fileSize;
    
    char * m_buffer;
    
    char * m_cursor;
    
    bool m_isOk;
    
public:
    CDFile(const char *path, size_t fileSize);
    ~CDFile();
    
    bool setCursor(size_t newCursor);
    
    bool append(const void *src, size_t len);
    
    bool putHex64(__uint64_t value);
    
    bool putHex32(__uint32_t value);
    
    bool putHex32WithOffset(__uint32_t value, size_t offset);
    
    bool putHex64WithOffset(__uint64_t value, size_t offset);
    
    bool end();
    
    bool is_ok();
};


#endif /* HMDCDFile_hpp */
