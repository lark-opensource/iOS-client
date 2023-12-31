//
// Created by xuzhi on 2021/7/12.
//

#include "domain_manager.h"
namespace hermas {
namespace infrastruct {

BaseDomainManager::BaseDomainManager(const std::shared_ptr<Env>& env) :
m_upload_service(UploadService::GetInstance(env->GetModuleEnv())),
m_network_service(NetworkService::GetInstance(env->GetModuleEnv())),
m_zstd_dict_service(ZstdService::GetInstance(env->GetModuleEnv())),
m_disater_service(DisasterService::GetInstance(env)) {
    // file + record 是针对Env的
    m_file_service = std::make_unique<hermas::FileService>(env);
    m_record_service = std::make_shared<hermas::RecordService>(env);
    m_cache_service = std::make_shared<hermas::CacheService>(env);
    m_search_service = std::make_shared<hermas::SearchService>(env);
    
    if (env->GetEnableSemiFinished()) {
        m_semifinished_service = std::make_shared<hermas::SemifinishedService>(env);
    }
    if (env->GetEnableAggregator()) {
        // setup aggregate service
        m_aggregate_service = std::make_shared<AggregateService>(env);
        m_aggregate_service->SetupClient(m_record_service);
    }
    
    // 注意循环依赖，如果有循环依赖，请使用weak_ptr处理
    m_record_service->InjectDepend(m_file_service, m_cache_service, m_aggregate_service, m_semifinished_service);
}

BaseDomainManager::~BaseDomainManager() {
    logi("hermas", "~BaseDomainManager start");
    logi("hermas", "~BaseDomainManager end");
}

}
}
