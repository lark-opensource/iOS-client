//
//  zstd_service.cpp
//  Hermas
//
//  Created by liuhan on 2022/3/3.
//

#include "zstd_service.h"
#include "user_default.h"
#include "time_util.h"
#include "zstd_util.h"
#include "json_util.h"
#include "base64_util.hpp"
#include "network_util.h"
#include <future>

#define UNDERLINE CHAR_LITERAL("_")

namespace hermas {

ZstdService::ZstdService(const std::shared_ptr<ModuleEnv>& module_env)
    : m_module_env(module_env)
    , m_network_service(NetworkService::GetInstance(module_env))
{
    m_available_time_identifier = "zstd_dict_available_time" + module_env->GetZstdDictType();
    m_zstd_dict_identifier = "zstd_dict" + module_env->GetZstdDictType();
    m_zstd_content_coding_identifier = "zstd_content_coding" + module_env->GetZstdDictType();
    m_zstd_dict_version_identifier = "zstd_dict_version" + module_env->GetZstdDictType();
    
    std::string available_time = UserDefault::Read(m_available_time_identifier);
    if (available_time.length()) {
        m_available_time = std::atol(available_time.c_str());
    }
    m_zstd_dict = UserDefault::Read(m_zstd_dict_identifier);
    m_zstd_dict_decoded = base64_decode(m_zstd_dict);
    m_zstd_content_coding = UserDefault::Read(m_zstd_content_coding_identifier);
    m_zstd_dict_version = UserDefault::Read(m_zstd_dict_version_identifier);
    
    // 此时网络请求时机过早，TTNet没有完全初始化完毕，容易崩溃，所以不再请求zstd的字典
}

std::string ZstdService::GetCompressedDataAndSyncHeader(const std::string& data, std::map<std::string, std::string>& header, bool& using_dict, double& compress_time) {
    std::string result;
    bool ret = CheckAndUpdateDict();
    if (ret) {
        using_dict = true;
        header.insert(pair<std::string, std::string>("slardar-zstd-version", GetDictVersion()));
        header.insert(pair<std::string, std::string>("Content-Encoding", GetContentCoding()));
        int64_t current_time = CurTimeMillis();
        result = zstd_compress_data_usingDic(data, GetDict());
        compress_time = CurTimeMillis() - current_time;
    } else {
        using_dict = false;
        header.insert(pair<std::string, std::string>("Content-Encoding", GetContentCoding()));
        int64_t current_time = CurTimeMillis();
        result = zstd_compress_data(data);
        compress_time = CurTimeMillis() - current_time;
    }
    return result;
}

bool ZstdService::CheckAndUpdateDict() {
    int64_t current_time = CurTimeSecond();
    if (m_available_time < current_time) {
        
        // App刚启动的时候，TTNet模块尚未初始化完成，此时网络请求时机过早，会造成crash，等待Heimdallr初始化完成后再请求
        if (!GlobalEnv::GetInstance().GetHeimdallrInitCompleted()) {
            return false;
        }
        
        if (!m_requesting.load(std::memory_order_acquire) && m_retry_time < 3) {
            m_requesting.store(true, std::memory_order_release);
            m_lock_mutex.lock();
            m_zstd_dict = "";
            m_zstd_dict_decoded = "";
            m_zstd_content_coding = "zstd";
            m_lock_mutex.unlock();
            
            m_future = std::async(std::launch::async, [this]() -> void {
                RequestDictFromServer();
            });
        }
        return false;
    }
    return true;
}


void ZstdService::RequestDictFromServer() {
    std::string url = urlWithHostAndPath(m_module_env->GetDomain(),  GlobalEnv::GetInstance().GetZstdDictPath()) + "?slardar_zstd_dict_type=" + m_module_env->GetZstdDictType() + "&device_platform=iOS";
    std::string method = "POST";
    std::map<std::string, std::string> header_field = {
        { "Content-Type", "application/json; encoding=utf-8" },
        { "Accept", "application/json" },
        { "sdk_aid", "2085" },
        { "Version-Code", "1"}
    };
    logi("hermas_zstd", "reqeust zstd dict from server, url = %s", url.c_str());
    
    HttpResponse response = m_network_service->UploadRecord(url, method, header_field, "");
    Json::Value json;
    bool ret = hermas::ParseFromJson(response.data, json);
    if (ret) {
        if (json["content_encoding"].isNull() || json["dict_version"].isNull() || json["dict"].isNull()) {
            logi("hermas_zstd", "content_encoding is null | dict_version is null | dict is null");
        } else {
            m_lock_mutex.lock();
            
            std::string encodedDict = json["dict"].asString();
            m_zstd_content_coding = json["content_encoding"].asString();
            m_zstd_dict_version = json["dict_version"].asString();
            m_zstd_dict = encodedDict;
            m_zstd_dict_decoded = base64_decode(encodedDict);
            m_available_time = CurTimeSecond() + 7 * 24 * 60 * 60;
            m_lock_mutex.unlock();
            
            logi("hermas_zstd", "success to obtain dict info, m_zstd_dict_version = %s, m_zstd_content_coding = %s", m_zstd_dict_version.c_str(), m_zstd_content_coding.c_str());
            
            UserDefault::Write(m_zstd_content_coding_identifier, m_zstd_content_coding);
            UserDefault::Write(m_zstd_dict_version_identifier, m_zstd_dict_version);
            UserDefault::Write(m_zstd_dict_identifier, m_zstd_dict);
            UserDefault::Write(m_available_time_identifier, std::to_string(m_available_time));
        }
    } else {
        logi("hermas_zstd", "failed to resolve the response to json");
    }
    ++m_retry_time;
    m_requesting.store(false, std::memory_order_release);
}

std::string ZstdService::GetDict() {
    m_lock_mutex.lock_shared();
    std::string dict = m_zstd_dict_decoded;
    m_lock_mutex.unlock_shared();
    return dict;
}

std::string ZstdService::GetDictVersion() {
    m_lock_mutex.lock_shared();
    std::string version = m_zstd_dict_version;
    m_lock_mutex.unlock_shared();
    return version;
}

std::string ZstdService::GetContentCoding() {
    m_lock_mutex.lock_shared();
    std::string coding = m_zstd_content_coding;
    m_lock_mutex.unlock_shared();
    return coding;
}

}
