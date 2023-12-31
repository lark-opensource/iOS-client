//
//  AWEMemoryGraphErrorDefines.hpp
//  MemoryGraphCapture
//
//  Created by brent.shu on 2020/2/4.
//

#ifndef AWEMemoryGraphErrorDefines_hpp
#define AWEMemoryGraphErrorDefines_hpp

#include <string>

namespace MemoryGraph {

enum ErrorType {
    None = 0,
    LogicalError,
    FileNotExist,
    GetFileStateFailed,
    ReadEmptyFile,
    InvalidRead,
    SeekFailed,
    InvalidReadResult,
    CreateDirFailed,
    CreateFileFailed,
    OpenFileFailed,
    CloseFileFailed,
    TruncateFileFailed,
    OverFileSizeLimit,
    MMapFailed,
    MunmapFailed,
    SuspendFailed,
    SystemOrDeviceNotSupported,
    NodesIsOverLimit,
    MemoryDoubleCheckFail,
    TimeOutError
};

class Error {
    ErrorType m_error;
public:
    bool is_ok;
    const char *m_ctx;
    
    Error(ErrorType type, const char *ctx): m_error(type), m_ctx(ctx), is_ok(type == None) {
    }
    
    Error(): m_error(None), m_ctx(nullptr), is_ok(true) {
    }
    
    Error& operator=(const Error &other)
    {
        m_error = other.m_error;
        m_ctx = other.m_ctx;
        is_ok = other.is_ok;
        return *this;
    }
    
    ErrorType type() const {
        return m_error;
    }
    
    std::string description() const {
        std::string desc = "";
        
        switch (m_error) {
            case ErrorType::None:
                desc.append("none error");
                break;
            case ErrorType::LogicalError:
                desc.append("internal logical error");
                break;
            case ErrorType::FileNotExist:
                desc.append("file not exist");
                break;
            case ErrorType::GetFileStateFailed:
                desc.append("get file state failed");
                break;
            case ErrorType::ReadEmptyFile:
                desc.append("trying read empty file");
                break;
            case ErrorType::InvalidRead:
                desc.append("invalid read bytes");
                break;
            case ErrorType::SeekFailed:
                desc.append("reader seek failed");
                break;
            case ErrorType::InvalidReadResult:
                desc.append("invalid read result");
                break;
            case ErrorType::CreateDirFailed:
                desc.append("create dir failed");
                break;
            case ErrorType::CreateFileFailed:
                desc.append("create file failed");
                break;
            case ErrorType::OpenFileFailed:
                desc.append("open file failed");
                break;
            case ErrorType::CloseFileFailed:
                desc.append("close file failed");
                break;
            case ErrorType::TruncateFileFailed:
                desc.append("truncate file failed");
                break;
            case ErrorType::OverFileSizeLimit:
                desc.append("over file size limit");
                break;
            case ErrorType::MMapFailed:
                desc.append("mmap failed");
                break;
            case ErrorType::MunmapFailed:
                desc.append("munmap failed");
                break;
            case ErrorType::SuspendFailed:
                desc.append("suspend failed");
                break;
            case ErrorType::SystemOrDeviceNotSupported:
                desc.append("system or device not supported");
                break;
            case ErrorType::MemoryDoubleCheckFail:
                desc.append("double check memory usage fail");
                break;
            case ErrorType::TimeOutError:
                desc.append("time out");
                break;
            default:
                break;
        }
        
        if (m_ctx) {
            desc.append(". context: " + std::string(m_ctx));
        }
        return desc;
    }
};

} // MemoryGraph

#endif /* AWEMemoryGraphErrorDefines_hpp */
