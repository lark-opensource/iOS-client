//
// Created by bytedance on 2020/8/6.
//

#ifndef HERMAS_MMAP_FILE_H
#define HERMAS_MMAP_FILE_H

#include <string>
#include <map>

#if PLATFORM_WIN
#include <windows.h>
#define FILE_HANDLE             HANDLE
#define INVALID_FILE_HANDLE     INVALID_HANDLE_VALUE
#define CLOSE_FILE_HANDLE       CloseHandle
#define INVALID_MMAP            INVALID_HANDLE_VALUE
#else
#define FILE_HANDLE     int
#define INVALID_FILE_HANDLE     -1
#define CLOSE_FILE_HANDLE       close
#define INVALID_MMAP            MAP_FAILED
#endif

#include "env.h"

namespace hermas {

static constexpr char NAME1 = 'h';
static constexpr char NAME2 = 'e';
static constexpr char NAME3 = 'r';
static constexpr char NAME4 = 'm';
static constexpr char NAME5 = 'a';
static constexpr char NAME6 = 's';

static const char FILE_HEAD[] = {
    NAME1, NAME2, NAME3, NAME4,
    NAME5, NAME6,
    0 /* file type */,
    0 /* encrypt */,
    0, 0, 0, 0, // content len
    0, 0, 0, 0, // offset
    0, 0, 0, 0, 0, 0, 0, 0, // start time
    0, 0, 0, 0, 0, 0, 0, 0 // end time
};

static constexpr int FILE_HEAD_INDEX_FILE_TYPE = 6;
static constexpr int FILE_HEAD_INDEX_ENCRYPT_VER = 7;
static constexpr int FILE_HEAD_INDEX_CONTENT_LEN = 8; // 内容长度，等同 m_content_len
static constexpr int FILE_HEAD_INDEX_OFFSET = 12; // 内容偏移，等同 m_offset
static constexpr int FILE_HEAD_INDEX_START_TIME = 16; // 内容偏移，等同 m_start_time
static constexpr int FILE_HEAD_INDEX_STOP_TIME = 24; // 内容偏移，等同 m_stop_time
static constexpr int FILE_HEAD_LEN = sizeof(FILE_HEAD);

class MmapFile {
public:
    
    MmapFile(const FilePath& file_path);
    virtual ~MmapFile();
public:
    enum E_FileType {
        FILE_TYPE_NONE = 0,
        FILE_TYPE_NORMAL = 1,
    };
    
    virtual const FilePath& GetFilePath() const;
    virtual E_FileType GetFileType() const;
    virtual Env::ERecordEncryptVer GetEncryptVersion() const;
    virtual int64_t GetStartTime() const;
    virtual int64_t GetStopTime() const;
    virtual void CloseFile();
    
protected:
    FilePath const m_file_path;
    E_FileType m_file_type;
    Env::ERecordEncryptVer m_encrypt_ver;
    FILE_HANDLE m_fd;
#if PLATFORM_WIN
    HANDLE m_hmap;
#endif
    int m_file_len; //文件总大小
    int m_content_len; //文件内容总大小
    int m_offset; //文件读取的偏移起始地址
    char *mp_mmap_file; //文件起始地址
    char *mp_mmap_file_offset; //文件当前的偏移指针
    int64_t m_start_time;
    int64_t m_stop_time;
};

} //namespace hermas

#endif //HERMAS_MMAP_FILE_H
