//
// Created by kilroy on 2021/1/29.
//

#ifndef HERMAS_NETWORK_SERVICE_H
#define HERMAS_NETWORK_SERVICE_H

#include <map>
#include <string>
#include <vector>
#include <atomic>

#include "protocol_service.h"
#include "env.h"
#include "base_domain.h"
#include "service_factory.hpp"

namespace hermas {

struct HttpResponse {
    bool is_success = false;
    long http_code = 0;
    std::string data;
};

class NetworkService final: public ServiceFactory<NetworkService>, public infrastruct::BaseDomainService<NetworkService> {
public:
    ~NetworkService();
    NetworkService(const NetworkService&) = delete;
    NetworkService& operator=(const NetworkService& ) = delete;
    
    HttpResponse UploadRecord(const std::string& url, const std::string& method, const std::map<std::string, std::string>& head_field, const std::string& data, bool need_encrypt = false);
    
    void UploadSuccess(const std::string& module_id);
    
    void UploadFailure(const std::string& module_id);
    
private:
    explicit NetworkService(const std::shared_ptr<ModuleEnv>& module_env);
    friend class ServiceFactory<NetworkService>;

private:
    std::shared_ptr<ModuleEnv> m_module_env;
};

} // namespace hermas
#endif // HERMAS_NETWORK_SERVICE_H
