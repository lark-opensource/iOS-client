//
//  file_service_util.cpp
//  Hermas
//
//  Created by 崔晓兵 on 25/2/2022.
//

#include "file_service_util.h"
#include "file_util.h"
#include "log.h"
#include "process_lock.h"
#include "mmap_read_file.h"
#include "vector_util.h"
#ifndef HERMAS_WIN
#include <dirent.h>
#include <unistd.h>
#define REMOVE_FILE(x) remove(x)
#else
#define REMOVE_FILE(x) _wremove(x)
#endif //HERMAS_WIN

#define UNDERLINE CHAR_LITERAL("_")

namespace hermas {

const FilePath GenPrepareDirPath(const std::shared_ptr<ModuleEnv>& module_env) {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(module_env->GetModuleId())
        .Append("prepare");
}

const FilePath GenReadyDirPath(const std::shared_ptr<ModuleEnv>& module_env) {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(module_env->GetModuleId())
        .Append("ready");
}


const FilePath GenCacheDirPath(const std::shared_ptr<ModuleEnv>& module_env) {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(module_env->GetModuleId())
        .Append("cache");
}

const FilePath GenLocalDirPath(const std::shared_ptr<ModuleEnv>& module_env) {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(module_env->GetModuleId())
        .Append("local");
}

const FilePath GenAggregateDirPath(const std::shared_ptr<ModuleEnv>& module_env) {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(module_env->GetModuleId())
        .Append("aggregation");
}

const FilePath GenSemifinishedDirPath(const std::shared_ptr<ModuleEnv>& module_env) {
    return GlobalEnv::GetInstance().GetRootPathName()
        .Append(module_env->GetModuleId())
        .Append("semifinished");
}


void RemoveFile(const FilePath& path) {
    if (REMOVE_FILE(path.charValue()) != 0) {
        logd("hermas_file", "failed to remove file: %s", path.sstrValue().c_str());
    }
}

void RemoveFile(const std::vector<FilePath> &paths) {
    for (auto iterator = paths.begin(); iterator != paths.end(); ++iterator) {
        logd("hermas_file", "remove file: %s", iterator->strValue().c_str());
        RemoveFile(*iterator);
    }
}

void RemoveFile(const std::string& path) {
    if (REMOVE_FILE(path.c_str()) != 0) {
        logd("hermas_file", "failed to remove file: %s", path.c_str());
    }
}

void RemoveFile(const std::vector<FilePath>& paths, std::vector<std::string>& aid_list) {
    for (auto iterator = paths.begin(); iterator != paths.end(); ++iterator) {
        if (IsVectorHasAssignedKey(aid_list, GetFileAid(*iterator))) {
            logd("hermas_file", "remove file: %s", iterator->strValue().c_str());
            RemoveFile(*iterator);
        }
    }
}

void RemoveFileWithDir(const FilePath& dir) {
    std::vector<FilePath> to_removed_files_name = GetFilesName(dir, FileSysType::kOnlyFile);
    for (auto& to_removed_file_name : to_removed_files_name) {
        FilePath to_removed_file = dir.Append(to_removed_file_name);
        RemoveFile(to_removed_file);
    }
}

void RemoveFileWithDirRecursively(const FilePath& dir) {
    std::vector<FilePath> to_removed_dir_names = GetFilesName(dir, FileSysType::kOnlyFolder);
    for(auto& dir_name : to_removed_dir_names) {
        const FilePath to_removed_dir = dir.Append(dir_name);
        RemoveFileWithDir(to_removed_dir);
    }
}


void RemoveFileWithAssignedDirAndAid(const FilePath& dir, const std::string& aid) {
    std::vector<FilePath> to_removed_files_name = GetFilesName(dir, FileSysType::kOnlyFile);
    for (auto& to_removed_file_name : to_removed_files_name) {
        FilePath to_removed_file = dir.Append(to_removed_file_name);
        if (aid == GetFileAid(to_removed_file)) {
            RemoveFile(to_removed_file);
        }
    }
}

void MovePrepareToReadyAndLocal(const std::shared_ptr<ModuleEnv>& module_env) {
    auto global_prepare_path = GenPrepareDirPath(module_env);
    std::vector<FilePath> aid_folders = GetFilesName(global_prepare_path, FileSysType::kOnlyFolder);
    for(auto& aid_fold : aid_folders) {
        const FilePath ready_path = global_prepare_path.Append(aid_fold);
        std::shared_ptr<FilesCollect> files_collect = std::make_shared<FilesCollect>(ready_path);
        while (files_collect->HasNextFile()) {
            auto file_path = files_collect->NextFilePath();
            std::string file_name = file_path.BaseName().sstrValue();
            std::string prefix = file_name.substr(0, file_name.find_first_of("_"));
            int type = std::stoi(prefix);
            
            if (type == LOCAL_RECORDER_TYPE) {
                FilePath target_path = GenLocalDirPath(module_env).Append(aid_fold).Append(file_path.FullBaseName());
                RenameFile(file_path, target_path);
            } else {
                FilePath target_path = GenReadyDirPath(module_env).Append(aid_fold).Append(TO_STRING(type)).Append(file_path.FullBaseName());
                RenameFile(file_path, target_path);
            }
        }
    }
}

FilesCollectQueue GetReadyDirs(const std::shared_ptr<ModuleEnv>& module_env) {
    FilesCollectQueue dir_queue;
    auto global_ready_path = GenReadyDirPath(module_env);
    std::vector<FilePath> aid_folders = GetFilesName(global_ready_path, FileSysType::kOnlyFolder);
    for(auto& aid_fold : aid_folders) {
        const FilePath ready_path = global_ready_path.Append(aid_fold);
        auto type_dirs = GetFilesName(ready_path, FileSysType::kOnlyFolder);
        for (int i = 0; i < type_dirs.size(); ++i) {
            //each ready type dir
            auto ready_type_path = ready_path.Append(type_dirs[i]);
            std::shared_ptr<FilesCollect> files_collect = std::make_shared<FilesCollect>(ready_type_path);
            dir_queue.push_back(std::move(files_collect));
        }
    }
    return dir_queue;
}


FilesCollectQueue GetReadyDirs(const std::shared_ptr<ModuleEnv>& module_env,
                                            const std::function<bool(const std::string&)>& filter) {
    FilesCollectQueue dir_queue;
    auto global_ready_path = GenReadyDirPath(module_env);
    std::vector<FilePath> aid_folders = GetFilesName(global_ready_path, FileSysType::kOnlyFolder);
    for(auto& aid_fold : aid_folders) {
        if (!filter(aid_fold.BaseName().strValue())) continue;
        const FilePath ready_path = global_ready_path.Append(aid_fold);
        auto type_dirs = GetFilesName(ready_path, FileSysType::kOnlyFolder);
        
        for (int i = 0; i < type_dirs.size(); ++i) {
            //each ready type dir
            auto ready_type_path = ready_path.Append(type_dirs[i]);
            std::shared_ptr<FilesCollect> files_collect = std::make_shared<FilesCollect>(ready_type_path);
            dir_queue.push_back(std::move(files_collect));
        }
    }
    return dir_queue;
}

std::vector<FilePath> GetReadyFiles(FilesCollectQueue &filesCollectQuene, bool (* compare)(const FilePath& item1, const FilePath& item2)) {
    std::vector<FilePath> ready_file_paths;
    while (!filesCollectQuene.empty()) {
        std::shared_ptr<FilesCollect>& file_collect = filesCollectQuene.front();
        while (file_collect->HasNextFile()) {
            ready_file_paths.push_back(file_collect->NextFilePath());
        }
        filesCollectQuene.pop_front();
    }
    if (ready_file_paths.size() > 1 && compare) {
        std::sort(ready_file_paths.begin(), ready_file_paths.end(), compare);
    }
    return ready_file_paths;
}

int64_t GetFileCreateTime(const FilePath& path) {
    std::string name = path.BaseName().strValue();
    size_t index = name.find_first_of("_");
    name = name.substr(index + 1);
    index = name.find_first_of("_");
    name = name.substr(0, index);
    int64_t timestamp = std::stoll(name);
    return timestamp;
}


std::tuple<int64_t, int64_t> GetFileStartAndStopTime(const std::shared_ptr<ModuleEnv>& module_env, const FilePath& path) {
    auto file_reader = std::make_unique<MmapReadFile>(path);
    bool ret = file_reader->OpenReadFile();
    if (!ret) return std::make_tuple(0, 0);
    int64_t start_time = file_reader->GetStartTime();
    int64_t stop_time = file_reader->GetStopTime();
    file_reader->CloseFile();
    return std::make_tuple(start_time, stop_time);
}

std::string GetFileAid(const FilePath& path) {
    if (path.sstrValue().length() == 0) return "";
    std::string aidDirName = path.DirName().DirName().strValue();
    size_t idx = aidDirName.find_last_of("/");
    std::string aid = aidDirName.substr(idx + 1);
    return aid;
}

void RemoveCacheDirPath(const std::shared_ptr<Env>& env) {
    auto dir_path = GenCacheDirPath(env->GetModuleEnv()).Append(env->GetAid());
    RemoveFileWithDir(dir_path);
}

void RemovePrepareDirPath(const std::shared_ptr<Env>& env) {
    auto dir_path = GenPrepareDirPath(env->GetModuleEnv()).Append(env->GetAid());
    RemoveFileWithDir(dir_path);
}

void RemoveLocalDirPath(const std::shared_ptr<Env>& env) {
    auto dir_path = GenLocalDirPath(env->GetModuleEnv()).Append(env->GetAid());
    RemoveFileWithDir(dir_path);
}

void RemoveReadyDirPath(const std::shared_ptr<Env>& env) {
    auto dir_path = GenReadyDirPath(env->GetModuleEnv()).Append(env->GetAid());
    RemoveFileWithDirRecursively(dir_path);
}

void RemoveAggregateDirPath(const std::shared_ptr<Env>& env) {
    auto dir_path = GenAggregateDirPath(env->GetModuleEnv()).Append(env->GetAid());
    RemoveFileWithDir(dir_path);
}

void RemoveSemifinishedDirPath(const std::shared_ptr<Env>& env) {
    auto dir_path = GenSemifinishedDirPath(env->GetModuleEnv()).Append(env->GetAid());
    RemoveFileWithDir(dir_path);
}

void MoveLocalToReady(const std::shared_ptr<Env>& env) {
    auto local_dir_path = GenLocalDirPath(env->GetModuleEnv()).Append(env->GetAid());
    std::shared_ptr<FilesCollect> files_collect = std::make_shared<FilesCollect>(local_dir_path);
    while (files_collect->HasNextFile()) {
        auto file_path = files_collect->NextFilePath();
        
        std::string file_name = file_path.FullBaseName().strValue();
        
        file_name = file_name.substr(file_name.find_first_of("_"));
        file_name = "15000" + file_name;
        
        FilePath target_path = GenReadyDirPath(env->GetModuleEnv()).Append(env->GetAid()).Append("15000").Append(file_name);
        RenameFile(file_path, target_path);
    }
}

}
