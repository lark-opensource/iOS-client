//
//  disaster_service.cpp
//  Hermas
//
//  Created by 崔晓兵 on 21/2/2022.
//

#include "disaster_service.h"
#include "time_util.h"
#include "json.h"
#include "user_default.h"
#include "network_service.h"
#include "json_util.h"
#include <pthread.h>
#include <future>
#include "string_util.h"
#include "domain_manager.h"
#include "network_util.h"

namespace hermas {

static const char *DisasterTag = "disaster_service";

ServerState operator|(ServerState f1, ServerState f2) {
    return (ServerState)( (int)f1 | (int)f2);
}

ServerState& operator|=(ServerState& f1, ServerState f2) {
    return f1 = f1 | f2;
}

DisasterService::DisasterService(const std::shared_ptr<Env>& env)
: m_env(env)
, m_network_service(NetworkService::GetInstance(m_env->GetModuleEnv())) {
    // obtain
    m_identifier_available_time = "identifier_aviaible_time_" + env->GetModuleId() + "_" + env->GetAid();
    m_identifier_server_state = "identifier_server_state" + env->GetModuleId() + "_" + env->GetAid();
    
    m_drop_data = false;
    m_next_aviaible_time_interval = -1;
    m_last_server_state = ServerStateUnknown;
    
    std::string errCodeStr = UserDefault::Read(m_identifier_server_state);
    if (errCodeStr.length() > 0) {
        m_last_server_state = ServerState(std::atoi(errCodeStr.c_str()));
    }
    
    std::string availableTimeStr = UserDefault::Read(m_identifier_available_time);
    if (availableTimeStr.length() > 0) {
        m_next_aviaible_time_interval = atof(availableTimeStr.c_str());
    }
    
    
    if ((m_last_server_state & ServerStateDropAllData) == ServerStateDropAllData ||
        (m_last_server_state & ServerStateDropData) == ServerStateDropData) {
        if (m_next_aviaible_time_interval != -1 && CurTimeSecond() < m_next_aviaible_time_interval) {
            //quota 状态为drop all data/drop data时，在长退避周期，客户端不生产数据
            m_drop_data = true;
        }
    }
    
    m_current_sleep_count = 0;
    m_current_sleep_value_for_exception = -1;
    m_next_quota_interval = -1;
    CheckAndRequestStateIfNeeded();
}

int64_t DisasterService::GetServerAviableTime() {
    return m_next_aviaible_time_interval;
}

ServerResult DisasterService::UpdateServerState(const std::string& data, int64_t status_code) {
    struct ServerResult serverResult;
    
    Json::Value json;
    bool ret = hermas::ParseFromJson(data, json);
    if (!ret) {
        serverResult.is_server_saved = false;
        serverResult.server_quato_state = ServerStateUnknown;
        return serverResult;
    }
    
    std::string message = "";
    bool is_saved = false;
    
    bool getMutipleAidMsgSuccess = false;
    if (json.isMember("aid_info")) {
        auto aid_info = json["aid_info"][m_env->GetAid()];
        if(aid_info.isMember("is_saved") && aid_info.isMember("message")) {
            std::string isSaved = StrToLower(aid_info["is_saved"].asString());
            if (isSaved.compare("true") == 0) {
                is_saved = true;
            } else {
                is_saved = false;
            }
            
            message = aid_info["message"].asString();
            getMutipleAidMsgSuccess = true;
        }
    }
    
    std::string redirect = "";
    int64_t delay = -1;
    if (!getMutipleAidMsgSuccess) {
        message = json["message"].asString();
        redirect = json["redirect"].asString();
        delay = json["delay"].asInt64();
    }
    
    double current_time = CurTimeSecond();
    
    
    m_lock_mutex.lock();
    
    ServerState error_code = ServerStateUnknown;
    m_drop_data = false;//默认新产生数据不丢弃
    
    // 成功
    if (status_code >= 200 && status_code <= 299 && message == "success") {
        m_next_aviaible_time_interval = -1;
        m_current_sleep_count = 0;
        error_code = ServerStateSuccess;
        logd(DisasterTag, "quota state = success, module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    }
    
    // drop data: 服务端不接收数据；本地不产生数据；长避退策略；退避周期结束时，上报前调用接口check quota状态
    if (message == "drop data") {
        ExexuteLongAvoidanceStrategy(current_time);
        m_drop_data = true;
        error_code |= ServerStateDropData;
        logi(DisasterTag, "quota state = drop data , module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    }
    // drop all data: 服务端不接收数据；本地不产生数据，删除未上传的所有数据；长避退策略；退避周期结束时，上报前调用接口check quota状态
    else if (message == "drop all data") {
        ExexuteLongAvoidanceStrategy(current_time);
        m_drop_data = true;
        error_code |= ServerStateDropAllData;
        logi(DisasterTag, "quota state = drop all data , module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    }
    // long escape: 服务端不接收数据；本地数据正常产生及保持；长避退策略；退避周期结束时，上报前调用接口check quota状态
    else if (message == "long escape") {
        ExexuteLongAvoidanceStrategy(current_time);
        error_code |= ServerStateLongEscape;
        logi(DisasterTag, "quota state = long escape , module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    }
    // 延迟
    else if (delay > 0) {
        m_next_aviaible_time_interval = current_time + delay;
        m_current_sleep_count = 0;
        error_code |= ServerStateDelay;
        logi(DisasterTag, "quota state = delay , module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    }
    // 长避退:statusCode == 500-599；退避周期结束时，上报前调用接口check quota状态
    else if (status_code > 499 && status_code < 600) {
        ExexuteLongAvoidanceStrategy(current_time);
        error_code |= ServerStateDelay;
        logi(DisasterTag, "quota state = delay , module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    }
    // 重试：连接超时等iOS系统网络错误
    // iOS 网络错误码 https://blog.csdn.net/qq_35139935/article/details/53067596
    else if (status_code < 200 || status_code > 499 || message == "ERR_TTNET_TRAFFIC_CONTROL_DROP") {
        error_code |= ServerStateUnknown;
        logi(DisasterTag, "quota state = ServerStateUnknown , module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    }
    
    // 域名重定向
    if (redirect.length() > 0) {
        m_redirect_host = redirect;
        error_code |= ServerStateRedirect;
    } else {
        m_redirect_host = "";
    }
    
    m_last_server_state = error_code;
    double time_to_write = m_next_aviaible_time_interval;
    
    m_lock_mutex.unlock();
    
    UserDefault::Write(m_identifier_available_time, std::to_string(time_to_write));
    UserDefault::Write(m_identifier_server_state, std::to_string(error_code));
    
    if (!getMutipleAidMsgSuccess && error_code != ServerStateUnknown) {
        is_saved = true;
    }
    serverResult.is_server_saved = is_saved;
    serverResult.server_quato_state = error_code;
    return serverResult;
}

bool DisasterService::IsServerAvailable() {
    m_lock_mutex.lock_shared();
    double time_interval = m_next_aviaible_time_interval;
    m_lock_mutex.unlock_shared();
    if (time_interval != -1 && CurTimeSecond() < time_interval) {
        return false;
    }
    return true;
}

bool DisasterService::NeedDropData() {
    m_lock_mutex.lock_shared();
    bool drop_data = m_drop_data;
    CheckAndRequestStateIfNeeded();
    m_lock_mutex.unlock_shared();
    
    return drop_data;
}

bool DisasterService::NeedDropAllData() {
    
    return false;
}

std::string DisasterService::RedirectHost() {
    m_lock_mutex.lock_shared();
    std::string host = m_redirect_host;
    m_lock_mutex.unlock_shared();
    return host;
}

void DisasterService::ExexuteShortAvoidanceStrategy(double current_time) {
    // 30秒起，策略是指数级，2^N次，即 15*2,15*4,15*8,最高到 5分钟（15 * 2^5), 即5次后达到
    if (m_current_sleep_count < 5) ++m_current_sleep_count;
    double delay = std::min(300.0, (1 << m_current_sleep_count) * short_delay_time_unit);
    m_next_aviaible_time_interval = current_time + delay;
    //非线程安全，但是只需要一个模糊的退避时间来控制容灾模块的开关
    if (m_next_aviaible_time_interval > max_next_aviable_time_interval) {
        max_next_aviable_time_interval = m_next_aviaible_time_interval;
        UserDefault::Write(max_next_aviable_time_interval_key, std::to_string(max_next_aviable_time_interval));
    }
}

void DisasterService::ExexuteLongAvoidanceStrategy(double current_time) {
    // 5分钟起，倍数级，最高30分钟
    if (m_current_sleep_count < 6) ++m_current_sleep_count;
    m_next_aviaible_time_interval = current_time + m_current_sleep_count * long_delay_time_unit;
    
    //非线程安全，但是只需要一个模糊的退避时间来控制容灾模块的开关
    if (m_next_aviaible_time_interval > max_next_aviable_time_interval) {
        max_next_aviable_time_interval = m_next_aviaible_time_interval;
        UserDefault::Write(max_next_aviable_time_interval_key, std::to_string(max_next_aviable_time_interval));
    }
}

void DisasterService::UpdateServerCheckerByQuota(const std::string& state) {
    m_lock_mutex.lock();
    if (state == "") {
        m_drop_data = false;
        m_next_aviaible_time_interval = -1;
        m_last_server_state = ServerStateSuccess;
        m_current_sleep_count = 0;
    }
    //quota状态为“drop all data”，本地不生产数据，长退避策略升级
    else if (state == "drop all data") {
        if ((m_last_server_state & ServerStateDropAllData) != ServerStateDropAllData) {
            //quota状态发生变化，长退避计数清零
            m_current_sleep_count = 0;
        }
        m_drop_data = true;
        
        // send message to record service to drop all data, include the ready directory
        auto& record_service = infrastruct::BaseDomainManager::GetInstance(m_env)->GetRecordService();
        record_service->DropAllData();
        
        this->ExexuteLongAvoidanceStrategy(CurTimeSecond());
        m_last_server_state = ServerStateDropAllData;
    }
    // quota状态为“long escape”，本地生产数据，保存数据到db(需要防止oom)，长退避策略升级
    else if (state == "long escape") {
        if ((m_last_server_state & ServerStateLongEscape) != ServerStateLongEscape) {
            //quota状态发生变化，长退避计数清零
            m_current_sleep_count = 0;
        }
        m_drop_data = false;
        this->ExexuteLongAvoidanceStrategy(CurTimeSecond());
        m_last_server_state = ServerStateLongEscape;
    }
    
    double time_to_write = m_next_aviaible_time_interval;
    ServerState error_code = m_last_server_state;
    
    m_lock_mutex.unlock();
    
    UserDefault::Write(m_identifier_available_time, std::to_string(time_to_write));
    UserDefault::Write(m_identifier_server_state, std::to_string(error_code));
}

void DisasterService::RequestStateFromServer() {
    // avoid frequent request
    if (m_next_quota_interval != -1 && CurTimeSecond() < m_next_quota_interval) {
        return;
    }
    m_next_quota_interval = CurTimeSecond() + short_delay_time_unit;
    
    std::string url = urlWithHostAndPath(m_env->GetModuleEnv()->GetDomain(), GlobalEnv::GetInstance().GetQuotaPath()) + "?" + GlobalEnv::GetInstance().GetQueryParams();
    std::string method = "POST";
    std::map<std::string, std::string> header_field= {
        { "Content-Type", "application/json; encoding=utf-8" },
        { "Accept", "application/json" },
        { "sdk_aid", "2085" },
        { "Version-Code", "1"}
    };
    
    Json::Value data;
    data["aid"] = atoi((m_env->GetAid()).c_str());
    data["os"] = "iOS";
    data["path"] = m_env->GetModuleEnv()->GetPath();
    
    HttpResponse response = m_network_service->UploadRecord(url, "POST", header_field, data.toStyledString());
    
    
    Json::Value result;
    bool ret = hermas::ParseFromJson(response.data, result);
    if (ret) {
        if (result["message"].isNull()) return;
        auto message = result["message"];
        if (message != "success") return;
        if (result["quota_status"].isNull()) return;;
        auto quota_status = result["quota_status"].asString();
        this->UpdateServerCheckerByQuota(quota_status);
    }
}

void DisasterService::CheckAndRequestStateIfNeeded() {
    // 长退避周期结束，此时需要检查quota状态，并更新本地容灾策略
    double current_time = CurTimeSecond();
    if (m_next_aviaible_time_interval != -1 && current_time + 15 > m_next_aviaible_time_interval && current_time > m_next_quota_interval) {
        
        // App刚启动的时候，TTNet模块尚未初始化完成，此时网络请求时机过早，会造成crash，等待Heimdallr初始化完成后再请求
        if (!GlobalEnv::GetInstance().GetHeimdallrInitCompleted()) {
            return;
        }
    
        // 如果正在网络请求中，返回
        bool is_requesting = m_is_requesting.load(std::memory_order_acquire);
        if (is_requesting) return;
        
        // 异步网络请求
        if(!m_is_requesting.compare_exchange_strong(is_requesting, true, std::memory_order_acq_rel, std::memory_order_acquire)) {
            return;
        }
        
        m_future = std::async(std::launch::async, [this]() -> void {
            RequestStateFromServer();
            m_is_requesting.store(false, std::memory_order_release);
        });
    }
}

}
