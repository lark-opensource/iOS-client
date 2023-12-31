//
//  disaster_service.hpp
//  Hermas
//
//  Created by 崔晓兵 on 21/2/2022.
//

#ifndef disaster_service_hpp
#define disaster_service_hpp

#include "env.h"
#include "rwlock.h"
#include "service_factory.hpp"
#include <future>

namespace hermas {
class IFlowControlStrategy;

// 容灾策略
enum ServerState {
    ServerStateUnknown     = 0,        // 没有灾难，上报成功与否未知
    ServerStateSuccess     = 1,        // 没有灾难，上报成功
    ServerStateDropData    = 1 << 1,   // 停止接收数据
    ServerStateDropAllData = 1 << 2,   // 停止接收数据，且删除以前所有数据
    ServerStateRedirect    = 1 << 3,   // 重定向上报域名
    ServerStateDelay       = 1 << 4,   // 触发避退策略
    ServerStateLongEscape  = 1 << 5,   // 服务端不接收数据；本地数据正常产生及保持；长避退策略
};

struct ServerResult
{
    ServerState server_quato_state;
    bool is_server_saved;
};

ServerState operator|(ServerState f1, ServerState f2);
ServerState& operator|=(ServerState& f1, ServerState f2);

class NetworkService;

class DisasterService final : public ServiceFactory<DisasterService> {
public:
    const double short_delay_time_unit = 15.f; // 短避退 以15秒为单位
    const double long_delay_time_unit = 300.f; // 长避退 以300秒为单位
    double max_next_aviable_time_interval = -1;
    const std::string max_next_aviable_time_interval_key = "max_next_aviable_time_interval_key";
   
public:
    ~DisasterService(){};
    
    bool IsServerAvailable();
    
    bool NeedDropData();
    
    bool NeedDropAllData();
    
    std::string RedirectHost();
    
    ServerResult UpdateServerState(const std::string& data, int64_t code);
    
    int64_t GetServerAviableTime();
    
private:
    explicit DisasterService(const std::shared_ptr<Env>& env);
    friend class ServiceFactory<DisasterService>;
    
private:
    void RequestStateFromServer();
    
    void CheckAndRequestStateIfNeeded();
    
    bool IsServerAbnormal();
    
    void ExexuteLongAvoidanceStrategy(double current_time);
    
    void ExexuteShortAvoidanceStrategy(double current_time);
    
    void UpdateServerCheckerByQuota(const std::string& state);

private:
    std::shared_ptr<Env> m_env;
    std::string m_identifier_available_time;
    std::string m_identifier_server_state;
    double m_next_aviaible_time_interval;
    int64_t m_current_sleep_count;
    int64_t m_current_sleep_value_for_exception;
    std::string m_redirect_host;
    double m_next_quota_interval;
    ServerState m_last_server_state;
    bool m_drop_data;
    bool m_drop_all_data;
    rwlock m_lock_mutex;
    std::unique_ptr<NetworkService>& m_network_service;
    std::future<void> m_future;
    std::atomic<bool> m_is_requesting;
};

} //namespace hermas

#endif /* disaster_service_hpp */
