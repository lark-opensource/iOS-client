//
// Created by bytedance on 2020/8/6.
//

#include "records.h"
#include "log.h"

namespace hermas {

Records::Records(const std::shared_ptr<Env>& env)
    : m_env(env)
    , m_record_struct_map()
{

}

Records::~Records() {
    auto it = m_record_struct_map.begin();
    while (it != m_record_struct_map.end()) {
        std::unique_ptr<IFileRecord>& file_record = it->second;
        if (file_record != nullptr) {
            file_record->Close();
        }
        ++it;
    }
    m_record_struct_map.clear();
}

void Records::SetFileService(const std::shared_ptr<FileService>& file_service) {
    m_file_service = file_service;
}

void Records::RecordFile(int type, const std::string& content) {
    // 1 create file
    if (m_record_struct_map.find(type) == m_record_struct_map.end()) {
        m_record_struct_map[type] = std::make_unique<FileRecord>(m_env, m_file_service, type);
        std::unique_ptr<IFileRecord>& file_record = m_record_struct_map[type];
        file_record->NewFile();
    }
    std::unique_ptr<IFileRecord>& file_record = m_record_struct_map[type];
    
    // 2 write file. if full, update file and write.
    IFileRecord::ERecordRet ret = file_record->Record(content);
    if (ret == IFileRecord::E_FAIL_OVER_SIZE) {
        loge("hermas_record", "file write over size first, it's maybe mmap file is full");
        //save and delete
        SaveFile(type);

        // then new again
        m_record_struct_map[type] = std::make_unique<FileRecord>(m_env, m_file_service, type);
        std::unique_ptr<IFileRecord>& file_record = m_record_struct_map[type];
        
        file_record->NewFile();

        // record
        ret = file_record->Record(content);
    }

    // 3 check ret
    if (ret == IFileRecord::E_FAIL_OVER_SIZE) {
        loge("hermas_record", "file write over size again, disk is full, data is miss!!!!!!");
//        m_env->GetModuleEnv()->GetErrorNotify().OnError(info);
    } else if (ret == IFileRecord::E_SUCCESS_MAX_LINE) {
        loge("hermas_record", "max line trigger to save file: %d", type);
        SaveFile(type);
    } else if (ret == IFileRecord::E_SUCCESS) {
        // go on
        logi("hermas_record", "record content success");
    }
}

/**
 * 保存文件的几处调用时机
 * 1 记录结束后调用
 * 2 班车超时后调用
 */
void Records::SaveFile(int type, bool need_drop)
{
    // 这里要判空一下，不然连续save的并且中间没有写入的话会崩溃
    if (m_record_struct_map.find(type) == m_record_struct_map.end()) {
        return;
    }
    
    logi("hermas_record", "move record file to ready file with type: %d", type);
    
    std::unique_ptr<IFileRecord>& file_record = m_record_struct_map[type];
    if (!file_record->IsFileValid()) {
        return;
    }

    // close
    auto file_path = file_record->GetFilePath();
    file_record->Close();

    // erase
    auto it = m_record_struct_map.find(type);
    m_record_struct_map.erase(it);

    // move closed file
    if (need_drop) {
        RemoveFile(file_path);
    } else {
        m_file_service->MoveFileReady(file_path, type);
    }
}
} //namespace hermas
