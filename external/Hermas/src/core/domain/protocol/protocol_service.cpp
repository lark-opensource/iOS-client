//
// Created by bytedance on 2020/8/10.
//
#include "protocol_service.h"

#include <stdio.h>

#include "time_util.h"
#include "env.h"
#ifdef HERMAS_PERFORMANCE
#include "platform.h"
#endif

#include "json_util.h"

#define PROTOCOL_HEAD "header"
#define PROTOCOL_BODY "data"
#define KEY_TIMESTAMP "timestamp"

namespace hermas {

std::string ProtocolService::GenRecordHead(const std::shared_ptr<Env>& env) {
    Json::Value head_json;
    auto low_level_header = env->GetReportLowLevelHeader();
    if (low_level_header != nullptr) {
        for (const auto& key: low_level_header->getMemberNames()) {
            head_json[key] = (*low_level_header)[key];
        }
    }
    
    auto& constant_header = GlobalEnv::GetInstance().GetReportConstantHeader();
    if (constant_header != nullptr) {
        for (const auto& key: constant_header->getMemberNames()) {
            head_json[key] = (*constant_header)[key];
        }
    }
    
    head_json["aid"] = env->GetAid();
    if (env->GetAid() != GlobalEnv::GetInstance().GetHostAid()) {
        head_json["host_aid"] = GlobalEnv::GetInstance().GetHostAid();
    }
    return head_json.toStyledString();
}

std::string ProtocolService::GenRecordBody(const std::string& body, const std::shared_ptr<Env>& env) {
    if (body.empty()) return body;
    Json::Value json;
    bool ret = hermas::ParseFromJson(body, json);
    if (!ret) return body;
    json[KEY_TIMESTAMP] = CurTimeSecond();
    return json.toStyledString();
}

std::string ProtocolService::GenUploadData(const std::vector<std::unique_ptr<RecordData>>& record_data_list, const std::shared_ptr<ModuleEnv>& module_env) {
    if (record_data_list.size() == 0) return "";
    Json::Value root_dic;
    Json::Value root_list;
    int index = 0;
    for (auto& rd : record_data_list) {
        if (rd->body.size() == 0) continue;
        
        Json::Value head_json;
        bool ret = hermas::ParseFromJson(rd->header, head_json);
        if (!ret) continue;
        
        head_json["is_hermas_upload"] = "1";
        
        Json::Value root;
        Json::Value body_json_array;
        Json::Value body_json;
        for (int i = 0; i < rd->body.size(); i++) {
            bool ret = hermas::ParseFromJson(rd->body[i], body_json);
            if (!ret) continue;
            body_json_array[i] = std::move(body_json);
        }
        
        if (body_json_array.size() == 0) continue;
        
        root[PROTOCOL_BODY] = std::move(body_json_array);
        root[PROTOCOL_HEAD] = std::move(head_json);
        
        root_list[index++] = root;
    }
    
    if (index == 0) return "";
    root_dic["list"] = root_list;
    return root_dic.toStyledString();
}

std::string ProtocolService::GenForwardData(const std::vector<std::unique_ptr<RecordData>>& record_data_list, const std::shared_ptr<ModuleEnv>& module_env) {
    if (record_data_list.size() == 0) return "";
    
    Json::Value root_dic;
    Json::Value root_list;
    
    Json::Value head_json;
    bool ret = hermas::ParseFromJson(record_data_list.front()->header, head_json);
    if (!ret) return "";
    
    Json::Value body_json_array;
    for (auto& rd : record_data_list) {
        if (rd->body.size() == 0) continue;
        Json::Value body_json;
        for (int i = 0; i < rd->body.size(); i++) {
            bool ret = hermas::ParseFromJson(rd->body[i], body_json);
            if (!ret) continue;
            body_json_array[i] = std::move(body_json);
        }
    }
    if (body_json_array.size() == 0) return "";
    
    root_dic[PROTOCOL_HEAD] = head_json;
    root_dic[PROTOCOL_BODY] = body_json_array;
    return root_dic.toStyledString();
}

}
