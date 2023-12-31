//
// Created by kilroy on 2021/1/29.
//
#include "network_service.h"

#include <stdio.h>
#include <chrono>
#include <thread>
#include <memory>

#include "file_util.h"
#include "log.h"
#include "json.h"
#include "iuploader.h"

namespace hermas {

NetworkService::NetworkService(const std::shared_ptr<ModuleEnv>& module_env)
    : m_module_env(module_env) {
    if (m_module_env->GetUploader() != nullptr) {
        logd("hermas_network", "Init net with external record uploader");
    }
}

NetworkService::~NetworkService() {
    
}

HttpResponse NetworkService::UploadRecord(const std::string& url, const std::string& method, const std::map<std::string, std::string>& head_field, const std::string& data, bool need_encrypt) {
    auto request = RequestStruct(url, method, head_field, data, need_encrypt);
    if (m_module_env && m_module_env->GetUploader()) {
        auto result = m_module_env->GetUploader()->Upload(request);
        struct HttpResponse response;
        response.is_success = (result->code >= 200 && result->code < 300);
        response.http_code = result->code;
        response.data = result->response_data;
        return response;
    } else {
        loge("hermas_network", "module_env or uploader is nil");
        struct HttpResponse response;
        return response;
    }
    
}

void NetworkService::UploadSuccess(const std::string& module_id) {
    m_module_env->GetUploader()->UploadSuccess(module_id);
}

void NetworkService::UploadFailure(const std::string& module_id) {
    m_module_env->GetUploader()->UploadFailure(module_id);
}


}
