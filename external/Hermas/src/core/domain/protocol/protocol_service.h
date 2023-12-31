//
// Created by bytedance on 2020/8/10.
//

#pragma once

#include <string>
#include <map>
#include <vector>

#include "env.h"
#include "json.h"
#include "json_util.h"
#include "forward_protocol.h"

namespace hermas {

class ProtocolService {
public:
    
    static std::string GenRecordHead(const std::shared_ptr<Env>& env);
    
    static std::string GenRecordBody(const std::string& body, const std::shared_ptr<Env>& env);

    static std::string GenUploadData(const std::vector<std::unique_ptr<RecordData>>& record_data_list, const std::shared_ptr<ModuleEnv>& module_env);
    
    static std::string GenForwardData(const std::vector<std::unique_ptr<RecordData>>& record_data_list, const std::shared_ptr<ModuleEnv>& module_env);
    
private:
    ProtocolService() = delete;
    ~ProtocolService() = delete;
};

}; // namespace hermas
