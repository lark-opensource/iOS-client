#include <mutex>
#include <shared_mutex>
#include <vector>
#include <assert.h>
#ifdef PLATFORM_LINUX
#include <cstring>
#endif

#include "log.h"
#include "recorder.h"
#include "hermas_internal.h"
#include "hermas.hpp"

namespace hermas {

std::shared_ptr<HermasInternal> Hermas::GetCurrentInstance() {
    return HermasInternal::GetInstance(m_module_id, m_aid);
}

Hermas::~Hermas() {
    logd("hermas_", "delete start");

    // delete all hermas and env instance
    std::unique_lock<rwlock> lc_guard(m_delete_lock_mutex);

    // free hermas
    logd("hermas_", "delete hermas start");
    vector<std::string> delete_key_list;
    auto map_weak_ptr = HermasInternal::GetHermasMap();
    auto map_ptr = map_weak_ptr.Lock();
    if (map_ptr) {
        auto& instance_map = map_ptr->GetItem();
        auto iterator = instance_map.begin();
        while (iterator != instance_map.end()) {
            std::shared_ptr<HermasInternal> instance = iterator->second;
            string find_str = string(m_module_id + AID_LINK_SYMBOL);
            if (instance != nullptr && (strstr(iterator->first.c_str(), find_str.c_str()) != nullptr)) {
                delete_key_list.push_back(iterator->first);
            }

            iterator++;
        }
        for (const auto& key : delete_key_list) {
            instance_map.erase(key);
        }
    }
    logd("hermas_", "delete hermas end");

    // free env and module env
    logd("hermas_", "delete module env start");
    WeakPtr<WeakModuleEnvMap> module_map_weak_ptr = ModuleEnv::GetModuleEnvMap();
    auto module_env_map = module_map_weak_ptr.Lock();
    if (module_env_map) {
        bool is_find_module_env = false;
        auto& map = module_env_map->GetItem();

        auto module_env_iterator = map.begin();
        while (module_env_iterator != map.end()) {
            std::shared_ptr<ModuleEnv> instance = module_env_iterator->second;
            if (instance != nullptr && module_env_iterator->first == m_module_id) {
                is_find_module_env = true;
            }

            module_env_iterator++;
        }
        if (is_find_module_env) {
            map.erase(m_module_id);
        }
    }
    logd("hermas_", "delete module env end");

    logd("hermas_", "delete env start");
    vector<std::string> env_delete_key_list;
    WeakPtr<WeakEnvMap> env_map_weak_ptr = Env::GetEnvMap();
    auto env_map = env_map_weak_ptr.Lock();
    if (env_map) {
        auto& map = env_map->GetItem();
        auto env_iterator = map.begin();
        while (env_iterator != map.end()) {
            string find_str = string(m_module_id + AID_LINK_SYMBOL);
            if ((strstr(env_iterator->first.c_str(), find_str.c_str()) != nullptr)) {
                env_delete_key_list.push_back(env_iterator->first);
            }

            env_iterator++;
        }
        for (const auto& key : env_delete_key_list) {
            map.erase(key);
        }
    }
    logd("hermas_", "delete env end");

    logd("hermas_", "delete end");
}

void Hermas::InitInstanceEnv(const std::shared_ptr<Env>& env) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    Env::InitInstance(env);
}

void Hermas::Upload() {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->Upload();
    }
}

std::shared_ptr<Recorder> Hermas::CreateRecorder(enum RECORD_INTERVAL interval) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr == nullptr) {
        return nullptr;
    }
    return std::make_shared<Recorder>(hermas_ptr, interval);
}

void Hermas::UploadWithFlushImmediately() {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->UploadWithFlushImmediately();
    }
}

bool Hermas::IsDropData() {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        return hermas_ptr->IsDropData();
    }
    return false;
}

bool Hermas::IsServerAvailable() {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        return hermas_ptr->IsServerAvailable();
    }
    return false;
}

void Hermas::CleanAllCache() {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->CleanAllCache();
    }
}

void Hermas::StopCache() {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->StopCache();
    }
}

void Hermas::Aggregate(const std::string& data) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->Aggregate(data);
    }
}

void Hermas::StopAggregate(bool isLaunchReport) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->StopAggregate(isLaunchReport);
    }
}

void Hermas::StartSemiTraceRecord(const std::string &content, const std::string &traceID) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->StartSemiTraceRecord(content, traceID);
    }
}

void Hermas::StartSemiSpanRecord(const std::string &content, const std::string &traceID, const std::string &spanID) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->StartSemiSpanRecord(content, traceID, spanID);
    }
}

void Hermas::FinishSemiTraceRecord(const std::string &data, const std::string &traceID, const std::string &spanIDList) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->FinishSemiTraceRecord(data, traceID, spanIDList);
    }
}

void Hermas::FinishSemiSpanRecord(const std::string &data, const std::string &traceID, const std::string &spanID) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->FinishSemiSpanRecord(data, traceID, spanID);
    }
}

void Hermas::DeleteSemifinishedRecords(const std::string &traceID, const std::string &spanIDList) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->DeleteSemifinishedRecords(traceID, spanIDList);
    }
}

void Hermas::LaunchReportForSemi() {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->LaunchReportForSemi();
    }
}

void Hermas::UpdateReportHeader(const std::string& header) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->UpdateReportHeader(header);
    }
}

std::vector<std::unique_ptr<SearchData>> Hermas::Search(const std::shared_ptr<ConditionNode> &condition) {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        return hermas_ptr->Search(condition);
    }
    return std::vector<std::unique_ptr<SearchData>>{};
}

void Hermas::UploadLocalData() {
    std::shared_lock<rwlock> lc_guard(m_delete_lock_mutex);
    auto hermas_ptr = GetCurrentInstance();
    if (hermas_ptr != nullptr) {
        hermas_ptr->UploadLocalData();
    }
}

}

