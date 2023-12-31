//
//  zstd_service.h
//  Hermas
//
//  Created by liuhan on 2022/3/3.
//

#ifndef zstd_dict_service_h
#define zstd_dict_service_h

#include "env.h"
#include "network_service.h"
#include "rwlock.h"
#include "service_factory.hpp"
#include <future>

namespace hermas {

class ZstdService final : public ServiceFactory<ZstdService> {
public:
    ~ZstdService(){};
    
    std::string GetCompressedDataAndSyncHeader(const std::string& data, std::map<std::string, std::string>& header, bool& using_dict, double& compress_time);
    
private:
    explicit ZstdService(const std::shared_ptr<ModuleEnv>& module_env);
    friend class ServiceFactory<ZstdService>;
    
private:
    void RequestDictFromServer();
    std::string GetDict();
    std::string GetContentCoding();
    std::string GetDictVersion();
    bool CheckAndUpdateDict();
    
private:
    std::shared_ptr<ModuleEnv> m_module_env;
    int64_t m_available_time = 0;
    int m_retry_time = 0;
    std::string m_zstd_dict_decoded;
    std::string m_zstd_dict;
    std::string m_zstd_content_coding = "zstd";
    std::string m_zstd_dict_version;
    std::string m_available_time_identifier;
    std::string m_zstd_dict_identifier;
    std::string m_zstd_content_coding_identifier;
    std::string m_zstd_dict_version_identifier;
    
    std::atomic<bool> m_requesting;
    
    rwlock m_lock_mutex;
    std::unique_ptr<NetworkService>& m_network_service;
    std::future<void> m_future;
};

}

#endif /* zstd_dict_service_hpp */
