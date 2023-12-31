//
// Created by bytedance on 2020/8/7.
//

#include "file_service.h"



#include <thread>
#include <algorithm>
#include <errno.h>

#include "log.h"
#include "file_util.h"
#include "time_util.h"

#define UNDERLINE CHAR_LITERAL("_")

namespace hermas {

FileService::FileService(const std::shared_ptr<Env>&env)
    : m_env(env)
    , m_running_file_lock_mutex()
{}

FileService::~FileService() {
    logi("hermas", "~FileService start");
    logi("hermas", "~FileService end");
}

std::unique_ptr<MmapWriteFile> FileService::NewFile(int type) {
	FilePath file_path = GenPrepareDirPath().Append(TO_STRING(type) + UNDERLINE + TO_STRING(CurTimeMillis()) + UNDERLINE + TO_STRING(m_file_id++) + UNDERLINE + m_env->GetPid() + UNDERLINE + CHAR_LITERAL("0"));

    // new mmap instance
    std::unique_ptr<MmapWriteFile> p_mmap_write_file = std::make_unique<MmapWriteFile>(file_path);

    // new file
    bool ret = p_mmap_write_file->CreateWriteFile(MmapFile::FILE_TYPE_NORMAL, Env::ERecordEncryptVer::NONE);
    if (!ret) {
        p_mmap_write_file.reset(new MmapWriteFile(file_path));

        // 第一次失败是没有文件夹，这里构建一下
		FilePath prepare_dir = GenPrepareDirPath();
        if (!Mkdirs(prepare_dir)) {
            logd("hermas_file", "mkdir parent path failed: %s", prepare_dir.sstrValue().c_str());
        }

        ret = p_mmap_write_file->CreateWriteFile(MmapFile::FILE_TYPE_NORMAL, Env::ERecordEncryptVer::NONE);
        if (!ret) {
            // 构建失败，则返回 0
            // TODO monitor
            loge("hermas_file", "new file fail ! file %s", file_path.sstrValue().c_str());
            return 0;
        }
    }

    return p_mmap_write_file;
}

bool FileService::WriteFile(MmapWriteFile* file_id, const char *data, int data_len, bool is_header) {
    if (file_id == nullptr) {
        // 0 说明之前构建失败，这里不再执行下去
        return false;
    }

    // write data
    return file_id->Write(data, data_len, is_header);
}

void FileService::CloseFile(MmapWriteFile* file_id) {
    if (file_id == nullptr) {
        // 0 说明之前构建失败，这里不再执行下去
        return;
    }

    // close file
    file_id->CloseFile();
}



const FilePath FileService::GetFilePath(MmapWriteFile* file_id) {
    if (file_id == nullptr) {
        return FilePath();
    }
    return file_id->GetFilePath();
}

/**
 * type 0 用来放泄漏的文件，即 IDLE_FILE_TYPE  // TODO 移动 IDLE_FILE_TYPE 到标准的 type 定义中
 */
void FileService::MoveFileReady(const FilePath& path, int type) {
    if (type == CACHE_RECORDER_TYPE) {
        FilePath target_path = GenCacheDirPath().Append(path.FullBaseName());
        RenameFile(path, target_path);
    } else if (type == LOCAL_RECORDER_TYPE) {
        FilePath target_path = GenLocalDirPath().Append(path.FullBaseName());
        RenameFile(path, target_path);
    } else {
        FilePath target_path = GenReadyDirPath().Append(TO_STRING(type)).Append(path.FullBaseName());
        RenameFile(path, target_path);
    }
}

void FileService::SaveFailData(std::string& process_name, const char *data, int64_t len) {
    // TODO : Save failed upload-data
}

const FilePath FileService::GenPrepareDirPath() {
	return GlobalEnv::GetInstance().GetRootPathName()
        .Append(m_env->GetModuleId())
        .Append("prepare")
        .Append(m_env->GetAid());
}

const FilePath FileService::GenReadyDirPath() {
	auto ready_dir = GlobalEnv::GetInstance().GetRootPathName()
        .Append(m_env->GetModuleId())
        .Append("ready")
        .Append(m_env->GetAid());
	return ready_dir;
}

const FilePath FileService::GenCacheDirPath() {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(m_env->GetModuleId())
        .Append("cache")
        .Append(m_env->GetAid());
}

const FilePath FileService::GenLocalDirPath() {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(m_env->GetModuleId())
        .Append("local")
        .Append(m_env->GetAid());
}



} // namespace hermas

