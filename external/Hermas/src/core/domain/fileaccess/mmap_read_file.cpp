//
// Created by bytedance on 2020/8/19.
//

#if PLATFORM_WIN
#include <windows.h>
#include <tchar.h>
#include <stdio.h>
#else
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <system_error>
#endif
#include <string.h>

#include "log.h"
#include "file_util.h"

#include "mmap_read_file.h"
#include "env.h"

using namespace hermas;

static const char* TAG = "hermas_file";

MmapReadFile::MmapReadFile(const FilePath& file_path) : MmapFile(file_path) { }

MmapReadFile::~MmapReadFile() { }

/**
 * Windows平台需要处理可能的EXCEPTION_IN_PAGE_ERROR，通过Structured Exception Handling
 * 详见：https://docs.microsoft.com/en-us/windows/win32/memory/reading-and-writing-from-a-file-view
 * __try __except需要单独的函数，不然会报对象展开的错误,
 * 详见：https://stackoverflow.com/questions/51701426/cannot-use-try-in-functions-that-require-object-unwinding-fix
 */
bool MmapReadFile::SafeRead() {
#ifdef PLATFORM_WIN
    __try {
#endif
        m_file_type = static_cast<E_FileType>(*(mp_mmap_file + FILE_HEAD_INDEX_FILE_TYPE));
        m_encrypt_ver = static_cast<Env::ERecordEncryptVer>(*(mp_mmap_file + FILE_HEAD_INDEX_ENCRYPT_VER));
        m_content_len = GetContentLen();
#ifdef PLATFORM_WIN
    } __except (GetExceptionCode() == EXCEPTION_IN_PAGE_ERROR ?
                EXCEPTION_EXECUTE_HANDLER : EXCEPTION_CONTINUE_SEARCH) {
        return false;
    }
#endif
    return true;
}

bool MmapReadFile::OpenReadFile() {
    bool ret = false;
    long long file_size = 0;
    const char* error_info = nullptr;
#define BREAK_IF(c, s)  if ( (c) ) { error_info = s; loge("hermas", s); break; }

    do {
#ifdef PLATFORM_WIN
		m_fd = CreateFile(m_file_path.charValue(),
						  GENERIC_WRITE | GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, 0,
						  OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
#else
		auto file_path = m_file_path.charValue();
        m_fd = open(file_path, O_RDWR, S_IRWXU|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
#endif
        BREAK_IF(m_fd < 0 || m_fd == INVALID_FILE_HANDLE, "open failed");

#ifdef PLATFORM_WIN
        //typedef int (*GETLARGEPAGEMINIMUM)(void);
        //HINSTANCE hDll = LoadLibrary(TEXT("kernal32.dll"));
        //BREAK_IF(hDll == NULL, "failed to load kernal32.dll");
        //GETLARGEPAGEMINIMUM fp_getpage_min = (GETLARGEPAGEMINIMUM)GetProcAddress(hDll, "GetLargePageMinimum");
        //BREAK_IF(fp_getpage_min == NULL, "failed to find GetLargePageMinimum addr");
        //int pagesize = static_cast<int>((*fp_getpage_min)());
        //FreeLibrary(hDll);
        SYSTEM_INFO si;
        GetSystemInfo(&si);
        int pagesize = si.dwPageSize;
#else 
        int pagesize = getpagesize();
#endif
        int min_file_size = (pagesize > 0) ? pagesize : FILE_HEAD_LEN;
        file_size = GetFileSize(m_file_path);
        BREAK_IF(file_size < min_file_size, "file size too small than page size");

#ifdef PLATFORM_WIN
        m_file_len = file_size;
        m_hmap = CreateFileMapping(m_fd, 0, PAGE_READWRITE, 0, 0, 0);
        BREAK_IF(NULL == m_hmap, "CreateFileMapping Error");
        mp_mmap_file = (LPSTR)MapViewOfFile(m_hmap, FILE_MAP_ALL_ACCESS, 0, 0, 0);
        BREAK_IF(mp_mmap_file == NULL, "MapViewOfFile Error");
#else
//        m_file_len = min_file_size;
//        mp_mmap_file = static_cast<char *>(mmap(nullptr, static_cast<size_t>(m_file_len), PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0));
//        BREAK_IF(INVALID_MMAP == mp_mmap_file, "mmap error")
//
//        int32_t content_len = GetContentLen();
//        BREAK_IF(!content_len || content_len > file_size, "get len error");
//
//        // Unmap
//        BREAK_IF(-1 == munmap(mp_mmap_file, m_file_len), "munmap error");
//
//        //judge file size
//        BREAK_IF(file_size < 0, "file size is negative");

        m_file_len = file_size;
        mp_mmap_file = static_cast<char *>(mmap(nullptr, static_cast<size_t>(m_file_len), PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0));
        BREAK_IF(INVALID_MMAP == mp_mmap_file, "re-mmap error");
#endif
        mp_mmap_file_offset = mp_mmap_file;
        // init file head
        mp_mmap_file_offset += FILE_HEAD_LEN;
        
        memcpy(&m_start_time, mp_mmap_file + FILE_HEAD_INDEX_START_TIME, sizeof(int64_t));
        memcpy(&m_stop_time, mp_mmap_file + FILE_HEAD_INDEX_STOP_TIME, sizeof(int64_t));
        

        if(!SafeRead()) {
            BREAK_IF(true, "exception happened in MmapReadFile::SafeRead function");
        }

        BREAK_IF(0 == m_content_len || m_content_len > file_size, "format version unsupported error");

        // All Done
        ret = true;
    } while ( false );

    if ( ret == false ) {
#ifdef PLATFORM_WIN
		int errcode = GetLastError();
#else
		int errcode = errno;
#endif
		loge(TAG, "file: %s, %s!! file_size = %lld, errorno = %d", m_file_path.sstrValue().c_str(), error_info, file_size, errcode);
		CloseFile();
    }
    return ret;
}


bool MmapReadFile::HasNext() {
    return mp_mmap_file_offset - mp_mmap_file < m_content_len;
}

std::string MmapReadFile::ReadNext() {
    int32_t record_len;
    memcpy(&record_len, mp_mmap_file_offset, sizeof(int32_t));

    if (record_len <= 0 || record_len > m_content_len - (mp_mmap_file_offset - mp_mmap_file))
    {
        //TODO monitor
#ifdef PLATFORM_WIN
		int errcode = GetLastError();
#else
		int errcode = errno;
#endif
		loge(TAG, "file: %s, total len %d, offset %d, read len %d, read record error!!, errorno = %d",
			 m_file_path.sstrValue().c_str(), m_content_len, mp_mmap_file_offset - mp_mmap_file, record_len, errcode);

        mp_mmap_file_offset = mp_mmap_file + m_content_len;
        return "";
    }
    mp_mmap_file_offset += sizeof(int);

    std::string record = std::string(mp_mmap_file_offset, static_cast<unsigned long>(record_len));
    mp_mmap_file_offset += record_len;

    return record;
}

int MmapReadFile::GetCurrentFileOffset() {
    int offset = mp_mmap_file_offset - mp_mmap_file;
    return offset;
}

bool MmapReadFile::IsOverMaxOpenRetryTimes() {
	auto path = m_file_path.strValue();
	int8_t retry_time = STR_TO_INT(path.substr(path.length() - 1, path.length()).c_str());
    return retry_time >= MAX_OPEN_RETRY_TIME - 1;
}

bool MmapReadFile::SetOffset(int32_t offset) {
    memcpy(mp_mmap_file + FILE_HEAD_INDEX_OFFSET, &offset, sizeof(int32_t));
    return true;
}

void MmapReadFile::SyncOffsetAfterReadHead() {
    m_offset = GetOffset();
    if (m_offset != 0) {
        mp_mmap_file_offset = mp_mmap_file;
        mp_mmap_file_offset += m_offset;
    }
}

void MmapReadFile::CloseFile() {
    MmapFile::CloseFile();
}

int32_t MmapReadFile::GetContentLen() {
    int32_t content_len;
    memcpy(&content_len, mp_mmap_file + FILE_HEAD_INDEX_CONTENT_LEN, sizeof(int32_t));
    return content_len;
}

int32_t MmapReadFile::GetOffset() {
    int32_t offset;
    memcpy(&offset, mp_mmap_file + FILE_HEAD_INDEX_OFFSET, sizeof(int32_t));
    return offset;
}
