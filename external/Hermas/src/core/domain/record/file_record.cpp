//
// Created by bytedance on 2020/8/6.
//

#include "file_record.h"
#include "log.h"

namespace hermas {

FileRecord::FileRecord(const std::shared_ptr<Env>& env, const std::shared_ptr<FileService> file_service, int type)
    : m_env(env)
    , m_file_service(file_service)
    , m_type(type)
    , m_is_head_wrote(false)
    , m_file_id(nullptr)
    , m_line_count(0){}

void FileRecord::NewFile()
{
    m_file_id = m_file_service->NewFile(m_type);
}

IFileRecord::ERecordRet FileRecord::Record(const std::string& content)
{
    // write head first
    if (!m_is_head_wrote)
    {
        m_is_head_wrote = true;

        std::string record_head = ProtocolService::GenRecordHead(m_env);
        bool ret = m_file_service->WriteFile(m_file_id.get(), record_head.c_str(), (int)record_head.length(), true);
        if (!ret)
        {
            loge("hermas_record", "error return when write head");
            return IFileRecord::E_FAIL_OVER_SIZE;
        }
    }

    // write body
    std::string record_body = ProtocolService::GenRecordBody(content, m_env);

    bool ret = m_file_service->WriteFile(m_file_id.get(), content.c_str(), (int)content.length());
    if (!ret)
    {
        loge("hermas_record", "error return when write body, unmemcpy has write before");
        return IFileRecord::E_FAIL_OVER_SIZE;
    }

    // if the type is LOCAL_RECORDER_TYPE or CACHE_RECORDER_TYPE, just ignore the line count
    if (m_type != LOCAL_RECORDER_TYPE && m_type != CACHE_RECORDER_TYPE) {
        m_line_count++;
        if (m_line_count >= GlobalEnv::GetInstance().GetMaxLogNumber()) {
            loge("hermas_record", "max line before write");
            return IFileRecord::E_SUCCESS_MAX_LINE;
        }
    }

    return IFileRecord::E_SUCCESS;
}

void FileRecord::Close()
{
    m_file_service->CloseFile(m_file_id.get());
    m_file_id.reset();
}

bool FileRecord::IsFileValid()
{
    return m_file_id != nullptr;
}

FilePath FileRecord::GetFilePath() {
    if (m_file_id == nullptr) {
        return FilePath();
    }
    
    return m_file_id->GetFilePath();
}
} //namespace hermas
