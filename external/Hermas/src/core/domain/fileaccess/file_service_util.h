//
//  file_service_util.hpp
//  Hermas
//
//  Created by 崔晓兵 on 25/2/2022.
//

#ifndef file_service_util_hpp
#define file_service_util_hpp

#include <vector>
#include "file_path.h"
#include "files_collect.h"
#include "env.h"

#include <deque>

namespace hermas {

static constexpr int REAL_RECORDER_TYPE = -1;
static constexpr int CACHE_RECORDER_TYPE = -2;
static constexpr int LOCAL_RECORDER_TYPE = -3;

using FilesCollectQueue = std::deque<std::shared_ptr<FilesCollect>>;

void RemoveFile(const FilePath& path);
void RemoveFile(const std::vector<FilePath>& paths);
void RemoveFile(const std::string& path);
void RemoveFile(const std::vector<FilePath>& paths, std::vector<std::string>& aid_list);
void RemoveFileWithDir(const FilePath& dir);
void RemoveFileWithDirRecursively(const FilePath& dir);
void RemoveFileWithAssignedDirAndAid(const FilePath& dir, const std::string& aid);


FilesCollectQueue GetReadyDirs(const std::shared_ptr<ModuleEnv>& module_env);
FilesCollectQueue GetReadyDirs(const std::shared_ptr<ModuleEnv>& module_env, const std::function<bool(const std::string&)>& filter);

std::vector<FilePath> GetReadyFiles(FilesCollectQueue &filesCollectQuene, bool (* compare)(const FilePath& item1, const FilePath& item2));

const FilePath GenPrepareDirPath(const std::shared_ptr<ModuleEnv>& module_env);
const FilePath GenReadyDirPath(const std::shared_ptr<ModuleEnv>& module_env);
const FilePath GenCacheDirPath(const std::shared_ptr<ModuleEnv>& module_env);
const FilePath GenLocalDirPath(const std::shared_ptr<ModuleEnv>& module_env);
const FilePath GenAggregateDirPath(const std::shared_ptr<ModuleEnv>& module_env);
const FilePath GenSemifinishedDirPath(const std::shared_ptr<ModuleEnv>& module_env);

void MovePrepareToReadyAndLocal(const std::shared_ptr<ModuleEnv>& module_env);
void MoveLocalToReady(const std::shared_ptr<Env>& env);

int64_t GetFileCreateTime(const FilePath& path);
std::tuple<int64_t, int64_t> GetFileStartAndStopTime(const std::shared_ptr<ModuleEnv>& module_env, const FilePath& path);
std::string GetFileAid(const FilePath& path);

void RemoveCacheDirPath(const std::shared_ptr<Env>& env);
void RemovePrepareDirPath(const std::shared_ptr<Env>& env);
void RemoveLocalDirPath(const std::shared_ptr<Env>& env);
void RemoveReadyDirPath(const std::shared_ptr<Env>& env);
void RemoveAggregateDirPath(const std::shared_ptr<Env>& env);
void RemoveSemifinishedDirPath(const std::shared_ptr<Env>& env);

}

#endif /* file_service_util_hpp */
