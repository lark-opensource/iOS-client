//
//  BDMMappedFile.hpp
//  BDALog
//
//  Created by kilroy on 2021/10/26.
//

#ifndef BDMMappedFile_hpp
#define BDMMappedFile_hpp

#include <stdio.h>
#include <string>
class BDMMappedFile {
public:
    BDMMappedFile(size_t file_size);
    ~BDMMappedFile() = default;
    bool Open(std::string file_path, bool is_private, bool readonly);
    void Close();
    char* GetData();
    size_t GetDataSize();
    bool IsOpen();
    
private:
    void Clear();
    void CloseFile();
    
    size_t data_size_;
    int fd_;
    char *data_;
    
};
#endif /* BDMMappedFile_hpp */
