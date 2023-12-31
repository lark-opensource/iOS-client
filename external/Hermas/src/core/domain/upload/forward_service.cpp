//
//  forward_service.cpp
//  Hermas
//
//  Created by 崔晓兵 on 23/2/2022.
//

#include "forward_service.h"
#include "network_service.h"
#include "zstd_util.h"
#include "json_util.h"
#include "log.h"
#include "forward_protocol.h"
#include "zstd_service.h"
#include "vector_util.h"
#include <regex>
#include "network_util.h"
namespace hermas {

void ForwardService::forward(const std::vector<std::unique_ptr<RecordData>>& record_data) {
    if (record_data.size() == 0) {
        logd("hermas_forward", "empty data to forward");
        return;
    }
    
    // match
    std::vector<std::unique_ptr<RecordData>> filter_record_data;
    for (auto& rd : record_data) {
        std::vector<std::string> filter_body_buffer;
        for (auto& line : rd->body) {
            Json::Value json;
            bool ret = hermas::ParseFromJson(line, json);
            if (!ret) {
                logi("hermas_forward", "failed to convert string to json %s", line.c_str());
                continue;
            }
            if (json["double_upload"].asBool()) {
                filter_body_buffer.push_back(line);
            }
        }
        
        if (filter_body_buffer.empty()) {
            continue;
        }
        auto filterRecord = std::make_unique<RecordData>();
        filterRecord->header = rd->header;
        filterRecord->body = filter_body_buffer;
        filter_record_data.push_back(std::move(filterRecord));
    }
    
    if (filter_record_data.size() == 0) {
        logi("hermas_forward", "empty data to forward");
        return;
    }
    
    std::string url = urlWithHostAndPath(m_module_env->GetForwardUrl());
    std::string forward_url = url + "?" + GlobalEnv::GetInstance().GetQueryParams();
    std::string method = "POST";
    std::string data = ProtocolService::GenForwardData(filter_record_data, m_module_env);
    std::map<std::string, std::string> header_field = {
        { "Content-Type", "application/json; encoding=utf-8" },
        { "Accept", "application/json" },
        { "sdk_aid", "2085" },
        { "Version-Code", "1"}
    };
    
    bool using_dict;
    bool need_encrypt = false;
    double compress_time;
    auto& zstd_service = ZstdService::GetInstance(m_module_env);
    HttpResponse result;
    auto& network_service = NetworkService::GetInstance(m_module_env);
    
    if (m_module_env->GetEnableRawUpload()) {
        logd("hermas_upload", "upload data: %s", data.c_str());
        // In debug env environment, we upload raw data instead of encryption for the convenience of debugging
        result = network_service->UploadRecord(forward_url, method, header_field, data);
    } else {
        std::string compress_data = zstd_service->GetCompressedDataAndSyncHeader(data, header_field, using_dict, compress_time);
        
        // encrypt
        if (m_module_env->GetEncryptEnabled() && m_module_env->GetEncryptHandler()) {
            need_encrypt = true;
            size_t before_comress_size = compress_data.size();
            compress_data = m_module_env->GetEncryptHandler()(compress_data);
            logi("hermas_forward", "before compress size: %d, after zstd compress size: %d, compress ratio = %.2f, using dic = %s, encrypt size = %d", data.size(), before_comress_size, before_comress_size * 1.0 / data.size(), (using_dict ? "true" : "false"), compress_data.size());
        } else {
            logi("hermas_forward", "before compress size: %d, after zstd compress size: %d, compress ratio = %.2f, using dic = %s ", data.size(), compress_data.size(), compress_data.size() * 1.0 / data.size(), (using_dict ? "true" : "false"));
        }
        
        result = network_service->UploadRecord(forward_url, method, header_field, compress_data, need_encrypt);
    }

    if (result.is_success) {
        logi("hermas_forward", "forward success, url = %s", forward_url.c_str());
    } else {
        loge("hermas_forward", "forward failure, url = %s", forward_url.c_str());
    }
}

}
