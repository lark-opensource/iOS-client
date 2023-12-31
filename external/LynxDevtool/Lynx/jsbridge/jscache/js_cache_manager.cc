// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/jscache/js_cache_manager.h"

#include <sys/stat.h>
#include <sys/types.h>

#include <fstream>
#include <thread>
#include <utility>

#include "base/file_utils.h"
#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "base/md5.h"
#include "base/path_utils.h"
#include "base/string/string_utils.h"
#include "base/trace_event/trace_event.h"
#include "jsbridge/runtime/runtime_constant.h"
#include "tasm/config.h"
#include "tasm/lynx_trace_event.h"

#if defined(OS_IOS) && LYNX_ENABLE_TRACING
#include "tracing/trace_event_devtool.h"
#endif

#if defined(OS_ANDROID)
#include "base/android/android_jni.h"
#include "tasm/react/android/environment_android.h"
#endif

#if defined(OS_WIN)
#include <io.h>

#include <cstdio>

#include "base/paths_win.h"
#else
#include <dirent.h>
#include <unistd.h>
#endif

namespace lynx {
namespace piper {
namespace cache {

static constexpr size_t MAX_SIZE = 50 * 1024 * 1024;  // 50MB

constexpr char METADATA_FILE_NAME[] = "meta.json";
constexpr auto MIN_ACCESS_TIME_UPDATE_INTERVAL = std::chrono::hours(24);

bool AbstractJsCacheManager::ReadFile(const std::string &filename,
                                      std::string &contents) {
  const std::string file_path = MakePath(filename);
  if (file_path.empty()) {
    LOGE("ReadFile failed (file_path is empty): " << filename);
    return false;
  }

  if (!base::FileUtils::ReadFileBinary(file_path, MAX_SIZE, contents)) {
    LOGE("ReadFile failed: " << file_path);
    return false;
  }
  return true;
}

bool AbstractJsCacheManager::WriteFile(const std::string &filename,
                                       uint8_t *out_buf, size_t out_buf_len) {
  std::string file_path = MakePath(filename);
  if (file_path.empty()) {
    LOGE("WriteFile failed (file_path is empty): " << filename);
    return false;
  }

  // write to temp file
  std::string temp_file_path = MakePath("temp.tmp");
  if (!base::FileUtils::WriteFileBinary(temp_file_path.c_str(), out_buf,
                                        out_buf_len)) {
    LOGE("WriteFile failed: " << file_path);
    return false;
  }

  // rename temp file to dest file
  remove(file_path.c_str());
  if (rename(temp_file_path.c_str(), file_path.c_str())) {
    remove(temp_file_path.c_str());
    LOGE("WriteFile failed (rename file failed): " << file_path);
    return false;
  }
  return true;
}

std::string AbstractJsCacheManager::MakeFilename(const std::string &file_md5) {
  return file_md5 + ".cache";
}

#if defined(OS_WIN)
std::string AbstractJsCacheManager::GetCacheDir() {
  if (!cache_path_.empty() || !IsCacheEnabled()) {
    return cache_path_;
  }
  auto [result, cache_dir] = lynx::base::GetExecutableDirectoryPath();
  if (!result) {
    can_create_cache_ = false;
    cache_path_ = "";
    return cache_path_;
  }

  auto cache_path = lynx::base::JoinPaths({cache_dir, CacheDirName()});
  if (lynx::base::DirectoryExists(cache_path)) {
    cache_path_ = cache_path;
    return cache_path_;
  }

  if (lynx::base::CreateDir(cache_path)) {
    LOGI("js_cache_dir created:" << cache_path);
  } else {
    LOGE("js_cache_dir create failed:");
    can_create_cache_ = false;
    cache_path_ = "";
    return cache_path_;
  }
  cache_path_ = cache_path;
  return cache_path_;
}
#elif defined(MODE_HEADLESS)
std::string AbstractJsCacheManager::GetCacheDir() {
  // This will actually disable cache
  return "";
}
#else
std::string AbstractJsCacheManager::GetCacheDir() {
  if (!cache_path_.empty() || !IsCacheEnabled()) {
    return cache_path_;
  }
#ifdef OS_ANDROID
  std::string cache_dir = base::android::EnvironmentAndroid::GetCacheDir();
#else
  // directory for unittest
  std::string cache_dir = "./";
#endif
  std::string cache_path =
      base::PathUtils::JoinPaths({cache_dir, CacheDirName()});
  if (access(cache_path.c_str(), R_OK) == 0) {
    cache_path_ = cache_path;
    return cache_path_;
  }
  int is_created = mkdir(cache_path.c_str(),
                         S_IRUSR | S_IWUSR | S_IXUSR | S_IRWXG | S_IRWXO);
  if (!is_created) {
    DLOGI("js_cache_dir created:" << cache_path);
  } else {
    LOGE("js_cache_dir create failed:" << is_created);
    can_create_cache_ = false;
    cache_path_ = "";
    return cache_path_;
  }
  cache_path_ = cache_path;
  return cache_path_;
}
#endif

std::string AbstractJsCacheManager::MakePath(const std::string &filename) {
  const std::string &cache_dir = GetCacheDir();
  if (cache_dir.empty()) {
    return cache_dir;
  }
  return base::PathUtils::JoinPaths({GetCacheDir(), filename});
}

bool AbstractJsCacheManager::IsCoreJS(const std::string &url) {
  return !url.compare(runtime::kLynxCoreJSName);
}

bool AbstractJsCacheManager::IsKernelJs(const std::string &url) {
  return IsCoreJS(url) || url.compare(runtime::kLynxCanvasJSName) == 0;
}

bool AbstractJsCacheManager::IsAppServiceJS(const std::string &url) {
  return !url.compare(runtime::kAppServiceJSName);
}

bool AbstractJsCacheManager::IsDynamicComponentServiceJS(
    const std::string &url) {
  return lynx::base::BeginsWith(url, runtime::kDynamicComponentJSPrefix) &&
         lynx::base::EndsWith(url, runtime::kAppServiceJSName);
}

bool AbstractJsCacheManager::IsCacheEnabled() {
  // TODO(zhenziqi) consider rename `IsQuickjsCacheEnabled` later
  // as this switch should also control the cache of v8 in the future
  return !base::LynxEnv::GetInstance().IsDevtoolEnabled() &&
         base::LynxEnv::GetInstance().IsQuickjsCacheEnabled() &&
         can_create_cache_;
}

// JsCacheManager

//
// request thread
//
std::shared_ptr<Buffer> JsCacheManager::TryGetCache(
    const std::string &source_url, const std::string &template_url,
    const std::shared_ptr<const Buffer> &buffer,
    std::unique_ptr<CacheGenerator> cache_generator) {
  if (!IsCacheEnabledForUrl(source_url)) {
    return nullptr;
  }

  LOGI("code cache enabled"
       << ", url: '" << source_url << "', template_url: '" << template_url
       << "', file_content size:" << buffer->size());

#if defined(OS_IOS)
#if LYNX_ENABLE_TRACING
  TRACE_EVENT_DEVTOOL(LYNX_TRACE_CATEGORY, nullptr,
                      [&source_url](TraceEvent *event) {
                        event->set_name("JsCacheManager::TryGetCache");
                        auto *debug = event->add_debug_annotations();
                        debug->set_name("source_url");
                        debug->set_string_value(source_url);
                      });
#endif
#else
  TRACE_EVENT(LYNX_TRACE_CATEGORY, nullptr,
              [&source_url](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("JsCacheManager::TryGetCache");
                auto *debug = ctx.event()->add_debug_annotations();
                debug->set_name("source_url");
                debug->set_string_value(source_url);
              });
#endif

  std::optional<std::string> md5_optional;
  std::scoped_lock<std::mutex> lock(cache_lock_);

  // try to load cache from memory
  if (IsKernelJs(source_url) && !cache_.empty()) {
    auto cache_it = cache_.find(EnsureMd5(buffer, md5_optional));
    if (cache_it != cache_.end()) {
      LOGI("cache loaded from memory, size: " << cache_it->second->size()
                                              << " bytes");
      return cache_it->second;
    }
  }

  auto identifier = BuildIdentifier(source_url, template_url);
  auto file_info = GetMetaData().GetFileInfo(identifier);
  if (file_info) {
    auto cache =
        LoadCacheFromStorage(*file_info, EnsureMd5(buffer, md5_optional));
    if (cache) {
      LOGI("cache loaded from storage, size: " << cache->size() << " bytes");
      if (IsKernelJs(source_url)) {
        SaveCacheToMemory(EnsureMd5(buffer, md5_optional), cache);
        LOGV("loaded cache saved to memory");
      }
      return cache;
    }
  } else {
    LOGI("no cache matches this url.");
  }

  PostTaskBackground(TaskInfo(TaskInfo::TaskType::GENERATE_CACHE,
                              std::move(identifier), std::move(md5_optional),
                              buffer, std::move(cache_generator)));
  return nullptr;
}

void JsCacheManager::RequestCacheGeneration(
    const std::string &source_url, const std::string &template_url,
    const std::shared_ptr<const Buffer> &buffer,
    std::unique_ptr<CacheGenerator> cache_generator, bool force) {
  LOGI("RequestCacheGeneration url: '"
       << source_url << "', template_url: '" << template_url
       << "', file_content size:" << buffer->size());
  if (!IsCacheEnabledForUrl(source_url)) {
    LOGI("code cache disabled");
    return;
  }

  auto identifier = BuildIdentifier(source_url, template_url);
  std::optional<std::string> md5_optional;
  PostTaskBackground(
      TaskInfo(force ? TaskInfo::TaskType::GENERATE_CACHE
                     : TaskInfo::TaskType::GENERATE_CACHE_IF_NEEDED,
               std::move(identifier), std::move(md5_optional), buffer,
               std::move(cache_generator)));
}

/*
 * 1. Check if the task is already inserted into the task list. If yes, return.
 * 2. Insert the task into the list.
 * 3. If make_cache_thread is not running, start it.
 */
void JsCacheManager::PostTaskBackground(TaskInfo task) {
  std::scoped_lock<std::mutex> lock(task_lock_);

  AdjustTaskListWithNewTask(std::move(task));

  if (task_list_.empty()) {
    return;
  }

  // start background thread if not started
  if (!background_thread_working_) {
    LOGI("start background thread to make cache");
    background_thread_working_ = true;
    std::thread make_cache_thread(&JsCacheManager::RunTasks, this);

#ifdef QUICKJS_CACHE_UNITTEST
    if (background_thread_for_testing_.joinable()) {
      background_thread_for_testing_.detach();
    }
    background_thread_for_testing_ = std::move(make_cache_thread);
#else
    make_cache_thread.detach();
#endif
  }
}

void JsCacheManager::AdjustTaskListWithNewTask(TaskInfo task) {
  auto iter = std::find_if(task_list_.begin(), task_list_.end(),
                           [&task](const TaskInfo &existed_task) {
                             return existed_task.identifier == task.identifier;
                           });

  // no task with same identifier exists, insert it
  if (iter == task_list_.end()) {
    task_list_.push_back(std::move(task));
    return;
  }

  // task with same identifier exists, replace it if the new task is more
  // promising. Otherwise ignore it.
  if (iter->type == TaskInfo::TaskType::GENERATE_CACHE_IF_NEEDED &&
      task.type == TaskInfo::TaskType::GENERATE_CACHE) {
    *iter = std::move(task);
  } else {
    LOGI("task already exists, ignore");
  }
}

//
// background thread
//

void JsCacheManager::RunTasks() {
  static std::once_flag clear_cache_flag;
  std::call_once(clear_cache_flag, &JsCacheManager::ClearExpiredCache, this);

#if defined(OS_ANDROID)
  base::android::AttachCurrentThread();
#endif

  while (true) {
    // 1. get task
    std::optional<std::reference_wrapper<TaskInfo>> task_ref;
    {
      std::scoped_lock<std::mutex> lock(task_lock_);
      if (task_list_.empty()) {
        background_thread_working_ = false;
#if defined(OS_ANDROID)
        base::android::DetachFromVM();
#endif
        return;
      }
      task_ref = task_list_.front();
    }

    // 2. run task
    RunTask(task_ref->get());

    // 3. pop task
    {
      std::scoped_lock<std::mutex> lock(task_lock_);
      task_list_.pop_front();
    }
  }
}

bool JsCacheManager::RunTask(TaskInfo &task) {
  auto start = std::chrono::high_resolution_clock::now();

  auto &[type, identifier, md5_optional, buffer, generator] = task;

  if (type == TaskInfo::TaskType::GENERATE_CACHE_IF_NEEDED) {
    if (auto info = GetMetaData().GetFileInfo(identifier)) {
      if (auto cache =
              LoadCacheFromStorage(*info, EnsureMd5(buffer, md5_optional))) {
        return true;
      }
    }
  }
  std::string file_md5 = EnsureMd5(buffer, md5_optional);

  LOGI("RunTask start"
       << ", url: '" << identifier.url << "', template_url: '"
       << identifier.template_url << "', file_md5: " << file_md5
       << ", buffer size: " << buffer->size() << " bytes");

  std::shared_ptr<Buffer> cache_buffer(generator->GenerateCache());
  if (!cache_buffer) {
    LOGE("GenerateCacheBuffer failed!");
    return false;
  }

  std::scoped_lock<std::mutex> guard(cache_lock_);
  if (IsKernelJs(identifier.url)) {
    SaveCacheToMemory(file_md5, cache_buffer);
  }

  if (!SaveCacheContentToStorage(identifier, cache_buffer, file_md5)) {
    LOGE("SaveCacheContentToStorage failed!");
    return false;
  }

  auto finish = std::chrono::high_resolution_clock::now();
  UNUSED_LOG_VARIABLE auto cost =
      std::chrono::duration_cast<std::chrono::nanoseconds>(finish - start)
          .count() /
      1000000.0;
  LOGI("MakeCache success, cache size: "
       << cache_buffer->size() << " bytes, time spent: " << cost << " ms");
  return true;
}

std::shared_ptr<Buffer> JsCacheManager::LoadCacheFromStorage(
    const CacheFileInfo &file_info, const std::string &file_md5) {
  std::string cache;
  if (file_info.md5 != file_md5 || !ReadFile(MakeFilename(file_md5), cache) ||
      cache.size() != file_info.cache_size) {
    if (file_info.md5 != file_md5) {
      LOGI("js file md5 mismatch.");
    } else {
      LOGI("cache file broken. cache size read from storage: "
           << cache.size()
           << ", size record in metadata: " << file_info.cache_size);
    }
    std::string path = MakePath(MakeFilename(file_info.md5));
    unlink(path.c_str());
    GetMetaData().RemoveFileInfo(file_info.identifier);
    // there's no need to save metadata to storage here. it will be saved
    // in the progress of generating cache later.
    return nullptr;
  }

  UpdateLastAccessTime(file_info);
  return std::make_shared<StringBuffer>(std::move(cache));
}

bool JsCacheManager::SaveCacheContentToStorage(
    const JsFileIdentifier &identifier, const std::shared_ptr<Buffer> &cache,
    const std::string &file_md5) {
  LOGI("SaveCacheContentToStorage template_url=' "
       << identifier.template_url << "', url='" << identifier.url << "'");
  GetMetaData().UpdateFileInfo(identifier, file_md5, cache->size());
  std::string json = GetMetaData().ToJson();
  LOGV("metadata: " << json);
  if (!WriteFile(METADATA_FILE_NAME, reinterpret_cast<uint8_t *>(json.data()),
                 json.size())) {
    LOGE("Write Metadata failed!");
    return false;
  }
  if (!WriteFile(MakeFilename(file_md5), const_cast<uint8_t *>(cache->data()),
                 cache->size())) {
    LOGE("Write Cache File failed!");
    return false;
  }
  return true;
}

// update only when (now - last_accessed) >= MIN_ACCESS_TIME_UPDATE_INTERVAL.
bool JsCacheManager::UpdateLastAccessTime(const CacheFileInfo &info) {
  auto now = std::chrono::system_clock::now();
  auto last_accessed = std::chrono::time_point<std::chrono::system_clock>(
      std::chrono::seconds(info.last_accessed));
  GetMetaData().UpdateLastAccessTimeIfExists(info.identifier);
  if (now - last_accessed < MIN_ACCESS_TIME_UPDATE_INTERVAL) {
    return true;
  }

  LOGI("UpdateLastAccessTime: " << info.identifier.template_url << " "
                                << info.identifier.url);
  std::string json = GetMetaData().ToJson();
  LOGV("metadata: " << json);
  if (!WriteFile(METADATA_FILE_NAME, reinterpret_cast<uint8_t *>(json.data()),
                 json.size())) {
    LOGE("Write Metadata failed!");
    return false;
  }
  return true;
}

void JsCacheManager::ClearExpiredCache() {
  std::lock_guard<std::mutex> lock(cache_lock_);
  auto begin = std::chrono::high_resolution_clock::now();
  auto info_list = GetMetaData().GetExpiredCacheFileInfo(ExpiredSeconds());
  for (auto &info : info_list) {
    auto file_name = MakeFilename(info.md5);
    unlink(MakePath(file_name).c_str());
    GetMetaData().RemoveFileInfo(info.identifier);
  }
  std::string json = GetMetaData().ToJson();
  LOGV("metadata: " << json);
  if (!WriteFile(METADATA_FILE_NAME, reinterpret_cast<uint8_t *>(json.data()),
                 json.size())) {
    LOGE("Write Metadata failed!");
  }
  auto finish = std::chrono::high_resolution_clock::now();
  UNUSED_LOG_VARIABLE auto cost =
      std::chrono::duration_cast<std::chrono::nanoseconds>(finish - begin)
          .count() /
      1000000.0;
  LOGI("ClearExpiredCache time spent: " << cost << " ms");
}

//
// util
//
MetaData &JsCacheManager::GetMetaData() {
  LoadMetadataIfNotLoaded();
  return *meta_data_;
}

void JsCacheManager::LoadMetadataIfNotLoaded() {
  if (meta_data_) {
    return;
  }

  std::string json;
  if (ReadFile(METADATA_FILE_NAME, json)) {
    meta_data_ = MetaData::ParseJson(json);
    if (meta_data_ != nullptr && meta_data_->GetLynxVersion() == LYNX_VERSION) {
      return;
    }
  }
  LOGI("Metadata load failed, clearing cache");
  ClearCacheDir();

  LOGI("Creating new Metadata");
  meta_data_ = std::make_unique<MetaData>(LYNX_VERSION);
}

#ifdef OS_WIN
void JsCacheManager::EnumerateFile(
    base::MoveOnlyClosure<void, const std::string &> func) {
  NOTREACHED();
}
#else
void JsCacheManager::EnumerateFile(
    base::MoveOnlyClosure<void, const std::string &> func) {
  auto path = GetCacheDir();
  DIR *dir = opendir(path.c_str());
  if (dir == nullptr) {
    return;
  }

  for (dirent *file = readdir(dir); file != nullptr; file = readdir(dir)) {
    if (strcmp(file->d_name, ".") && strcmp(file->d_name, "..")) {
      auto file_path = base::PathUtils::JoinPaths({path, file->d_name});
      func(file_path);
    }
  }
  closedir(dir);
}
#endif

#ifdef OS_WIN
void JsCacheManager::ClearCacheDir() { NOTREACHED(); }
#else
void JsCacheManager::ClearCacheDir() {
  LOGI("Clearing cache dir");
  EnumerateFile([](const std::string &file_path) {
    if (unlink(file_path.c_str())) {
      LOGE("remove file failed, file: " << file_path << " errno: " << errno);
    }
  });
}
#endif

int64_t JsCacheManager::ExpiredSeconds() {
  // TODO(zhenziqi) let user decide the expired time
  // 15 days for now
  return 15 * 24 * 3600;
}

const std::string &JsCacheManager::EnsureMd5(
    const std::shared_ptr<const Buffer> &buffer,
    std::optional<std::string> &md5_str) {
  if (!md5_str.has_value()) {
    md5_str = base::md5(reinterpret_cast<const char *>(buffer->data()),
                        buffer->size());
  }
  return *md5_str;
}

std::string JsCacheManager::GetSourceCategory(const std::string &source_url) {
  if (IsCoreJS(source_url)) {
    return MetaData::CORE_JS;
  } else if (IsDynamicComponentServiceJS(source_url) ||
             IsKernelJs(source_url)) {
    return MetaData::DYNAMIC;
  } else {
    return MetaData::PACKAGED;
  }
}

JsFileIdentifier JsCacheManager::BuildIdentifier(
    const std::string &source_url, const std::string &template_url) {
  JsFileIdentifier identifier;
  identifier.url = source_url;
  identifier.template_url = template_url;
  identifier.category = GetSourceCategory(source_url);
  return identifier;
}

bool JsCacheManager::IsJsFileSupported(const std::string &source_url) {
  return IsKernelJs(source_url) || IsAppServiceJS(source_url) ||
         IsDynamicComponentServiceJS(source_url);
}

bool JsCacheManager::IsCacheEnabledForUrl(const std::string &source_url) {
  // only support android for now
#if !defined(OS_ANDROID) && !defined(QUICKJS_CACHE_UNITTEST)
  return false;
#endif

  if (!IsCacheEnabled()) {
    LOGI("code cache disabled by switch");
    return false;
  }

  if (!IsJsFileSupported(source_url)) {
    LOGI("source_url is not supported: " << source_url);
    return false;
  }

  return true;
}

}  // namespace cache
}  // namespace piper
}  // namespace lynx
