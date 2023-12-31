//
// Created by bytedance on 2020/8/7.
//

#ifndef HERMAS_PROCESS_LOCK_H
#define HERMAS_PROCESS_LOCK_H

#if PLATFORM_WIN
#include <windows.h>
#endif

#include "file_path.h"

namespace hermas {
/*
    Use file lock inside
*/
class ProcessLock {
public:
    ProcessLock(const FilePath& lock_file);
    virtual ~ProcessLock();

public:
    // Get Cached Lock File Path
    const FilePath& GetFilePath() const;
    // Try Lock the file, return 
    bool TryLock(bool is_create_file = false);
    // Unlock the file
    void Unlock() volatile;

private:
	FilePath m_lock_file;
#ifdef PLATFORM_WIN
    HANDLE  m_fd;
#else
    int     m_fd;
#endif
};

} //namespace hermas

#endif //HERMAS_PROCESS_LOCK_H
