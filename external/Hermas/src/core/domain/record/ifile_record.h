//
// Created by bytedance on 2020/8/6.
//

#ifndef HERMAS_INTERFACE_FILE_RECORD_H
#define HERMAS_INTERFACE_FILE_RECORD_H

#include <string>
#include "file_path.h"

namespace hermas {

struct IFileRecord {
    enum ERecordRet {
        E_SUCCESS = 0,
        E_FAIL_OVER_SIZE = 1,
        E_SUCCESS_MAX_LINE = 2
    };
    
    virtual ~IFileRecord() = default;
    virtual void NewFile() = 0;
    virtual ERecordRet Record(const std::string& content) = 0;
    virtual void Close() = 0;
    virtual bool IsFileValid() = 0;
    virtual FilePath GetFilePath() = 0;
};

} //namespace hermas


#endif //HERMAS_INTERFACE_FILE_RECORD_H
