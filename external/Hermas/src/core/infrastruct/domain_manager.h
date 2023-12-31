//
// Created by xuzhi on 2021/7/12.
//

#ifndef HERMAS_DOMAIN_MANAGER_H
#define HERMAS_DOMAIN_MANAGER_H

#include "base_domain.h"
#include "file_service.h"
#include "record_service.h"
#include "upload_service.h"
#include "network_service.h"
#include "cache_service.h"
#include "search_service.h"
#include "aggregate_service.h"
#include "disaster_service.h"
#include "zstd_service.h"
#include "semfinished_service.h"
#include "service_factory.hpp"

namespace hermas {
namespace infrastruct {

class BaseDomainManager : public ServiceFactory<BaseDomainManager> {
public:
    ~BaseDomainManager();

    std::shared_ptr<hermas::FileService>& GetFileService() {
        return m_file_service;
    }
    std::shared_ptr<hermas::RecordService>& GetRecordService() {
        return m_record_service;
    }
    std::unique_ptr<hermas::UploadService>& GetUploadService() {
        return m_upload_service;
    }
    std::unique_ptr<hermas::NetworkService>& GetNetworkService() {
        return m_network_service;
    }
    std::shared_ptr<hermas::CacheService>& GetCacheService() {
        return m_cache_service;
    }
    std::shared_ptr<hermas::SearchService>& GetSerachService() {
        return m_search_service;
    }
    std::shared_ptr<hermas::AggregateService>& GetAggregateService() {
        return m_aggregate_service;
    }
    
    std::shared_ptr<hermas::SemifinishedService>& GetSemifinishedService() {
        return m_semifinished_service;
    }
    
    std::unique_ptr<hermas::DisasterService>& GetDisasterService() {
        return m_disater_service;
    }
    
    std::unique_ptr<hermas::ZstdService>& GetZstdService() {
        return m_zstd_dict_service;
    }
    
public:
    explicit BaseDomainManager(const std::shared_ptr<Env>& env);
    friend class ServiceFactory<BaseDomainManager>;
	
private:
    std::shared_ptr<hermas::FileService> m_file_service;
    std::shared_ptr<hermas::RecordService> m_record_service;
    std::shared_ptr<hermas::CacheService> m_cache_service;
    std::shared_ptr<hermas::SearchService> m_search_service;
    
    std::shared_ptr<hermas::AggregateService> m_aggregate_service = nullptr;
    std::shared_ptr<hermas::SemifinishedService> m_semifinished_service = nullptr;
    
    std::unique_ptr<hermas::UploadService>& m_upload_service;
    std::unique_ptr<hermas::NetworkService>& m_network_service;
    std::unique_ptr<hermas::ZstdService>& m_zstd_dict_service;
    std::unique_ptr<hermas::DisasterService>& m_disater_service;
    
};

} //namespace infrastruct
} //namespace hermas

#endif //HERMAS_DOMAIN_MANAGER_H
