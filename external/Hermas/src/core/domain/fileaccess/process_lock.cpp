//
// Created by bytedance on 2020/8/7.
//

#ifndef PLATFORM_WIN
#include <sys/file.h>
#include <unistd.h>
#endif

#include <cstring>
#include <errno.h>

#include "log.h"
#include "process_lock.h"

namespace hermas {

static const char* Tag = "hermas_file";

#ifdef PLATFORM_WIN
#define _INVALID_FD_    INVALID_HANDLE_VALUE
#define _CLOSE_FD_      CloseHandle
#define _REMOVE_FD_     DeleteFile
#else
#define _INVALID_FD_    -1
#define _CLOSE_FD_      close
#define _REMOVE_FD_     remove 
#endif

ProcessLock::ProcessLock(const FilePath& lock_file)
        : m_lock_file(lock_file), m_fd(_INVALID_FD_) { }

ProcessLock::~ProcessLock() {
    Unlock();
}

const FilePath& ProcessLock::GetFilePath() const {
    return m_lock_file;
}

bool ProcessLock::TryLock(bool is_create_file) {
    if (m_fd != _INVALID_FD_ && is_create_file) {
        _CLOSE_FD_(m_fd);

        m_fd = _INVALID_FD_;
        _REMOVE_FD_(m_lock_file.charValue());
    }

    // Need to create file
    if (m_fd == _INVALID_FD_) {
#ifdef PLATFORM_WIN
        m_fd = CreateFile(m_lock_file.charValue(), GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, 0, NULL);
        logd("hermas_file", "open lock file: %d, %d", m_fd, errno);
#else
        m_fd = open(m_lock_file.charValue(), O_WRONLY | (is_create_file ? O_CREAT : 0), S_IRWXU|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
#endif
    }

    if (m_fd == _INVALID_FD_) {
        loge(Tag, "TryLock open errno = %s, m_lock_file = %s, errno = %d", strerror(errno), m_lock_file.sstrValue().c_str(), errno);
        return false;
    }

#ifdef PLATFORM_WIN
    OVERLAPPED overlapvar = { 0 };
    bool ret = LockFileEx(m_fd, LOCKFILE_EXCLUSIVE_LOCK | LOCKFILE_FAIL_IMMEDIATELY, 0, 0, 0, &overlapvar);

    if (!ret) {
        loge(Tag, "TryLock LockFileEx failed, m_lock_file = %s, errno = %d", m_lock_file.sstrValue().c_str(), GetLastError());
    }
#else
    int res = flock(m_fd, LOCK_EX | LOCK_NB);

    if (res != 0 && errno != EAGAIN) {
        loge(Tag, "TryLock flock errno = %s, m_lock_file = %s, errno = %d", strerror(errno), m_lock_file.sstrValue().c_str(), errno);
    }
    
    //logd("hermas_file", "lock file: %s, res: %d", m_lock_file.sstrValue().c_str(), res);
    bool ret = (res == 0);
#endif

    return ret;
}

void ProcessLock::Unlock() volatile {
    if (m_fd == _INVALID_FD_) return;

#ifdef PLATFORM_WIN
    bool ret = UnlockFile(m_fd, 0, 0, 0, 0);
#else
    flock(m_fd, LOCK_UN);
#endif

    _CLOSE_FD_(m_fd);
    m_fd = _INVALID_FD_;
}

} //namespace hermas
