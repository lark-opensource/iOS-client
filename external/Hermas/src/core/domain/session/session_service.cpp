//
//  session_service.cpp
//  Hermas
//
//  Created by liuhan on 2022/2/24.
//

#include <stdio.h>
#include "session_service.h"
#include "log.h"
#include "file_util.h"
#include "file_service_util.h"
#include <unistd.h>

namespace hermas {

SessionService::SessionService(const std::string& session_dir_path) : session_dir_path(FilePath(session_dir_path)) {
    NewSessionFile();
}

void SessionService::UpdateSessionRecord(const std::string& sessionRecord) {
    // write session record
    if (sessionRecord.length() == 0) return;
    if (session_file_id == nullptr) {
        loge("hermas_session_file", "session_file_id is nil.");
        return;
    }
    bool ret = session_file_id->WriteRecordAndLength(sessionRecord.c_str(), (int32_t)sessionRecord.length(), 0);
    if (!ret) {
        loge("hermas_session_file", "write session failed");
    }
}

std::string SessionService::GetLatestSession() {
    int32_t record_len = session_file_id->ReadRecordLength(0, sizeof(int32_t));
    std::string sessionRecord = session_file_id->ReadAggreFile(sizeof(int32_t), record_len);
    return sessionRecord;
}

void SessionService::NewSessionFile() {
    int page_size = std::max(1024 * 10, getpagesize());
    FilePath file_path = session_dir_path.Append("session_file");
    // new mmap instance
    session_file_id = std::make_unique<AggreMmapFile>(file_path);
    if (IsFileExits(file_path)) {
        bool ret = session_file_id->OpenAggreFile();
        if (!ret) {
            RemoveFile(file_path);
            NewSessionFile();
        }
    } else {
        bool ret = session_file_id->CreatAggreFile(page_size);
        if (!ret) {
            session_file_id.reset(new AggreMmapFile(file_path));
            
            // First failure was because no matched dir
            FilePath session_dir = session_dir_path;
            if (!Mkdirs(session_dir)) {
                loge("hermas_dir", "make session dir fail ! dir %s", session_dir.sstrValue().c_str());
            }
            ret = session_file_id->CreatAggreFile(page_size);
            if (!ret) {
                // 构建失败
                session_file_id.reset();
                // TODO monitor
                loge("hermas_file", "new session file fail ! file %s", file_path.sstrValue().c_str());
                return;
            }
        }
    }
}

}
