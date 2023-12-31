//
//  record_aggregation.cpp
//  Hermas
//
//  Created by liuhan on 2022/1/17.
//

#include "record_aggregation.h"
#include "protocol_service.h"
#include "file_service.h"
#include "file_util.h"
#include "time_util.h"

#define UNDERLINE CHAR_LITERAL("_")
#define ISFree CHAR_LITERAL("1")
#define UNFree CHAR_LITERAL("0")
#define CONFIG_FILE_HEADER_LENGTH 42

using namespace hermas;

static const char* AggregationTag = "Hermas_Aggregation";

RecordAggregation::RecordAggregation(std::string& app_id, std::string& module_name, FilePath& root_path, int file_size, std::map<int, int>& file_config, std::map<std::string, std::vector<std::string>>& aggre_into_max)
    : m_app_id(app_id)
    , m_module_name(module_name)
    , m_is_stoping(false)
    , m_root_path(root_path)
    , m_aggre_into_max(aggre_into_max)
{
    VertifyConfigIsValid(file_size, file_config);
    NewAggreFile();
}

void RecordAggregation::VertifyConfigIsValid(int file_size, const std::map<int, int> &file_config) {
    if (file_size <= 0 || file_config.size() <= 0) {
        logi(AggregationTag, "Either not set file size and file configor or assigned file size is 0 and file config is nil.");
        return;
    }
    
    int need_file_size = 0;
    for (auto &iter : file_config) {
        need_file_size += iter.first * iter.second;
    }
    if (need_file_size <= file_size) {
        m_file_size = file_size;
        m_file_config = file_config;
        return;
    }
    
    loge(AggregationTag, "Assigned file size and file config are invalid. file size = %s, file config = %", file_size);
}

void RecordAggregation::GenFileStrust() {
    for (auto& iter : m_file_config) {
        int block_count = iter.second;
        std::vector<block_flag> block_vector;
        for (int i = 0; i < block_count ; i++) {
            struct block_flag blockFlag;
            blockFlag.is_free = '1';
            blockFlag.aggre_count = 0;
            blockFlag.aggre_key = "";
            block_vector.push_back(blockFlag);
        }
        m_file_struct[iter.first] = block_vector;
    }
}

void RecordAggregation::NewAggreFile() {
    GenFileStrust();
    // gen file path
    FilePath file_path = GenAggreDirPath().Append(TO_STRING(CurTimeMillis()) + UNDERLINE);
    // new aggre mmap instance
    m_aggre_file_id = std::make_unique<AggreMmapFile>(file_path);
    
    //new file
    bool ret = m_aggre_file_id->CreatAggreFile(m_file_size);
    if (!ret) {
        // First failure was because no matched dir
        FilePath aggre_dir = GenAggreDirPath();
        if (!Mkdirs(aggre_dir)) {
            loge(AggregationTag, "Make aggre dir failed. file path = %s", file_path.strValue().c_str());
            return;
        }
        ret = m_aggre_file_id->CreatAggreFile(m_file_size);
        if (!ret) {
            loge(AggregationTag, "Create aggre file failed. file path = %s", file_path.strValue().c_str());
            return;
        }
    }
    
    // gen config file
    FilePath config_file_path = FilePath(file_path.strValue() + "config");
    
    InitAggreConfigFile(config_file_path);
}

void RecordAggregation::InitAggreConfigFile(const FilePath& file_path) {
    int block_count = 0;
    for (auto& iter : m_file_config) {
        block_count += iter.second;
    }
    if (m_aggre_config_file_id == nullptr) {
        m_aggre_config_file_id = std::make_unique<AggreMmapFile>(file_path);
        bool ret = m_aggre_config_file_id->CreatAggreFile(CONFIG_FILE_HEADER_LENGTH + block_count);
        if (!ret) {
            loge(AggregationTag, "Create aggre config file failed. file path = %s", file_path.strValue().c_str());
            m_aggre_file_id->CloseFile();
            RemoveFile(m_aggre_file_id->m_file_path);
            return;
        }
    }
    
    Json::Value config_json;
    for (auto& iter : m_file_config) {
        config_json[to_string(iter.first)] = iter.second;
    }
    std::string config_str = config_json.toStyledString();
    config_str.resize(CONFIG_FILE_HEADER_LENGTH, ' ');
    bool ret = m_aggre_config_file_id->WriteAggreFile(config_str.c_str(), config_str.length(), 0);
    if (!ret) {
        loge(AggregationTag, "initilize aggre config file failed.");
        FreeFiles();
        return;
    }
    
    std::string file_flag_str(block_count, '1');
    ret = m_aggre_config_file_id->WriteAggreFile(file_flag_str.c_str(), file_flag_str.length(), CONFIG_FILE_HEADER_LENGTH);
    if (!ret) {
        loge(AggregationTag, "initilize aggre config file failed.");
        FreeFiles();
        return;
    }
}


void RecordAggregation::DoRecordAggregation(std::string& record) {
    if (record.empty()) return;
    std::string aggre_key = GenAggreKey(record);
    if (aggre_key.length() == 0) {
        RecordToPrepare(record);
        return;
    }
    int32_t size = record.length();
    int matched_area_index = -1;
    int matched_block_index = -1;
    int free_block_index = -1;
    int16_t max_aggre_count = 0;
    int max_aggre_count_block_index = -1;
    std::map<int, std::vector<block_flag>>::iterator iter;
    
    if (m_aggre_file_id == nullptr || m_aggre_config_file_id == nullptr) {
        NewAggreFile();
    }
    if (m_aggre_file_id == nullptr || m_aggre_config_file_id == nullptr) {
        logi(AggregationTag, "aggregate fd is null or the corresponding config fd is null");
        return;
    }
    
    // 遍历所有分区
    bool is_over_size = true;
    for (iter = m_file_struct.begin(); iter != m_file_struct.end(); iter++) {
        matched_area_index++;
        // 找出最小符合record的分区并遍历所有数据块
        if (size <= iter->first - 1) {
            is_over_size = false;
            for (int i = 0; i < iter->second.size(); i++) {
                // 定位最大聚合次数
                if (iter->second[i].aggre_count > max_aggre_count) {
                    max_aggre_count = iter->second[i].aggre_count;
                    max_aggre_count_block_index = i;
                }
                
                if (iter->second[i].is_free == '1') {
                    free_block_index = i;
                } else if (aggre_key == iter->second[i].aggre_key) {
                    matched_block_index = i;
                    break;
                }
            }
            if (free_block_index == -1 && matched_block_index == -1) {
                //key无匹配且无空位，聚合最多数据迁移到prepare并插入
                int32_t replace_file_offset = CalculateFileOffset(matched_area_index, max_aggre_count_block_index);
                std::string old_record = m_aggre_file_id->ReadAggreFile(replace_file_offset, iter->first);
                // 清除补充后缀
                old_record.erase(old_record.find_last_not_of(" ") + 1);
                RecordToPrepare(old_record);
                record.resize(iter->first, ' ');
                bool ret = m_aggre_file_id->WriteAggreFile(record.c_str(), record.length(), replace_file_offset);
                if (!ret) {
                    loge(AggregationTag, "DoRecordAggregation: Write aggre record failed. record = %s, record length = %d", record.c_str(), record.length());
                    return;
                }
                m_file_struct[iter->first][max_aggre_count_block_index].is_free = '0';
                m_file_struct[iter->first][max_aggre_count_block_index].aggre_key = aggre_key;
                m_file_struct[iter->first][max_aggre_count_block_index].aggre_count = 1;
            } else if (matched_block_index == -1 && free_block_index >= 0) {
                //key不匹配但是有空位，直接插入
                int32_t insert_file_offset = CalculateFileOffset(matched_area_index, free_block_index);
                record.resize(iter->first, ' ');
                bool ret = m_aggre_file_id->WriteAggreFile(record.c_str(), record.length(), insert_file_offset);
                if (!ret) {
                    loge(AggregationTag, "DoRecordAggregation: Write aggre record failed. record = %s, record length = %d", record.c_str(), record.length());
                    return;
                }
                m_file_struct[iter->first][free_block_index].is_free = '0';
                m_file_struct[iter->first][free_block_index].aggre_key = aggre_key;
                m_file_struct[iter->first][free_block_index].aggre_count = 1;
                
                int flag_offset = CONFIG_FILE_HEADER_LENGTH + free_block_index;
                for (auto key : m_file_config) {
                    if (key.first < iter->first) {
                        flag_offset += key.second;
                    } else {
                        break;
                    }
                }
                ret = m_aggre_config_file_id->WriteAggreFile(UNFree, 1, flag_offset);
            } else if (matched_block_index >= 0) {
                //key匹配，聚合后替换
                //读来数据，聚合计算
                int32_t aggre_file_offset = CalculateFileOffset(matched_area_index, matched_block_index);
                std::string old_record = m_aggre_file_id->ReadAggreFile(aggre_file_offset, iter->first);
                if (old_record.empty()) {
                    loge(AggregationTag, "DoRecordAggregation: old record is empty, offset = %d, block len = %d", aggre_file_offset, iter->first);
                }
                // 清除补充后缀
                old_record.erase(old_record.find_last_not_of(" ") + 1);
                std::string new_record = AggreRecord(old_record, record);
                new_record.resize(iter->first, ' ');
                bool ret = m_aggre_file_id->WriteAggreFile(new_record.c_str(), new_record.length(), aggre_file_offset);
                if (!ret) {
                    loge(AggregationTag, "DoRecordAggregation: Write aggre record failed. record = %s, record length = %d", record.c_str(), record.length());
                    return;
                }
                m_file_struct[iter->first][matched_block_index].aggre_key = aggre_key;
                m_file_struct[iter->first][matched_block_index].aggre_count += 1;
            }
            break;
        }
    
    }
    if (is_over_size) {
        RecordToPrepare(record);
    }
    return;
}

int32_t RecordAggregation::CalculateFileOffset(int area_index, int block_index) {
    int32_t fileOffset = 0;
    std::map<int, int>::iterator iter;
    for (iter = m_file_config.begin(); iter != m_file_config.end(); iter++) {
        if (area_index > 0) {
            fileOffset += iter->first * iter->second;
        } else if (area_index == 0) {
            fileOffset += block_index * iter->first;
        } else {
            break;
        }
        area_index--;
    }
    return fileOffset;
}

std::string RecordAggregation::AggreRecord(std::string& old_record, std::string& new_record) {
    Json::Value old_json;
    Json::Value new_json;
    bool ret = hermas::ParseFromJson(old_record, old_json);
    if (!ret) {
        loge(AggregationTag, "AggreRecord: Prase old record string failed. record = %s", old_record.c_str());
        return new_record;
    }
    ret = hermas::ParseFromJson(new_record, new_json);
    if (!ret) {
        loge(AggregationTag, "AggreRecord: Prase new record string failed. record = %s", new_record.c_str());
        return new_record;
    }
    
    for (const auto& key: new_json.getMemberNames()) {
        if (new_json[key].isNumeric() && (new_json[key].asDouble() < old_json[key].asDouble())) {
            new_json[key] = old_json[key];
        }
    }
    
    Json::Value old_extra_values = old_json["extra_values"];
    Json::Value new_extra_values = new_json["extra_values"];
    std::string service = old_json["service"].asString();
    for (const auto& key: new_extra_values.getMemberNames()) {
        if (!m_aggre_into_max.empty()
            && (m_aggre_into_max.find(service) != m_aggre_into_max.end())
            && (std::find(m_aggre_into_max[service].begin(), m_aggre_into_max[service].end(), key)) != m_aggre_into_max[service].end()) {
            if (new_extra_values[key].isNumeric() && (new_extra_values[key].asDouble() < old_extra_values[key].asDouble())) {
                new_extra_values[key] = old_extra_values[key];
            }
        } else {
            new_extra_values[key] = (new_extra_values[key].asDouble() + old_extra_values[key].asDouble()) / 2;
        }
    }
    
    new_json["extra_values"] = new_extra_values;
    return new_json.toStyledString();
}

std::string RecordAggregation::GenAggreKey(std::string& record) {
    // key
    Json::Value record_json;
    std::string aggreKey;
    bool ret = hermas::ParseFromJson(record, record_json);
    if (!ret) {
        return "";
    }
    
    if (record_json.isMember("service")) {
        aggreKey = record_json["service"].asString();
    }else {
        return "";
    }
    
    Json::Value extra_status;
    if (record_json.isMember("extra_status")) {
        extra_status = record_json["extra_status"];
        for (const auto& statusKey: extra_status.getMemberNames()) {
            aggreKey = aggreKey + UNDERLINE + extra_status[statusKey].asString();
        }
    } else {
        return "";
    }
    
    
    return aggreKey;
}

const FilePath RecordAggregation::GenAggreDirPath() {
    return m_root_path
        .Append(m_module_name)
        .Append("aggregation")
        .Append(m_app_id);
}

# warning: 保证config和aggre是对应的
void RecordAggregation::LaunchReportForAggre() {
    if (m_is_stoping) {
        return;
    }
    std::unique_ptr<AggreMmapFile> aggre_file_id_tmp;
    std::map<int, int> file_config_tmp;
    std::vector<int> is_free_tmp;
    int block_count = 0;
    
    std::vector<FilePath> aggre_and_config_files = GetFilesName(GenAggreDirPath(), FileSysType::kOnlyFile);
    if (aggre_and_config_files.empty() || aggre_and_config_files.size() == 0) {
        return;
    }
    m_is_stoping = true;
    EraseInvalidFiles(aggre_and_config_files);
    for (auto& aggre_and_config_file : aggre_and_config_files) {
        std::string findstr = aggre_and_config_file.strValue().substr(0, aggre_and_config_file.strValue().find("_"));
        // skip current file
        if (!m_aggre_file_id || m_aggre_file_id->m_file_path.strValue().find(findstr) != std::string::npos) {
            continue;
        }
        
        FilePath last_launch_file = GenAggreDirPath().Append(aggre_and_config_file);
        if (aggre_and_config_file.strValue().find("config") != std::string::npos) {
            if (aggre_file_id_tmp == nullptr || aggre_file_id_tmp->m_file_path.strValue().length() == 0) {
                remove(last_launch_file.charValue());
                logi(AggregationTag, "Launch Report: No matched aggre file");
                continue;
            }
            block_count = 0;
            is_free_tmp.clear();
            file_config_tmp.clear();
            
            // aggre config file
            std::string file_config_content = GetFileData(last_launch_file);
            if (file_config_content.empty() || file_config_content.length() == 0) {
                logi(AggregationTag, "Launch Report: Aggre config file is nil. file path = %s", last_launch_file.strValue().c_str());
                remove(last_launch_file.charValue());
                remove(aggre_file_id_tmp->m_file_path.charValue());
                continue;
            }
            std::string file_struct_config_str = file_config_content.substr(0, CONFIG_FILE_HEADER_LENGTH);
            Json::Value file_config_json;
            bool ret = hermas::ParseFromJson(file_struct_config_str, file_config_json);
            if (!ret) {
                loge(AggregationTag, "Launch Report: Parse aggre config failed. file path = %s", last_launch_file.strValue().c_str());
                remove(last_launch_file.charValue());
                remove(aggre_file_id_tmp->m_file_path.charValue());
                continue;
            }
            
            if (file_config_json.type() != Json::objectValue) {
                loge(AggregationTag, "Launch Report: Parse aggre config unexpected. file path = %s, string = %s", last_launch_file.strValue().c_str(), file_struct_config_str.c_str());
                remove(last_launch_file.charValue());
                remove(aggre_file_id_tmp->m_file_path.charValue());
                continue;
            }
            
            for (auto& key : file_config_json.getMemberNames()) {
                file_config_tmp[STR_TO_INT(key.c_str())] = file_config_json[key].asInt();
                block_count += file_config_json[key].asInt();
            }
            std::string is_free_str = file_config_content.substr(CONFIG_FILE_HEADER_LENGTH, block_count);
            
            for (int i = 0; i < is_free_str.length(); i++) {
                is_free_tmp.push_back(STR_TO_INT(is_free_str.substr(i, 1).c_str()));
            }
            ret = aggre_file_id_tmp->OpenAggreFile();
            if (!ret) {
                loge(AggregationTag, "To Prepare: Open aggre file failed.")
            } else {
                ReportAllDataWithFile(file_config_tmp, is_free_tmp, aggre_file_id_tmp);
            }
            aggre_file_id_tmp->CloseFile();
            remove(last_launch_file.charValue());
            remove(aggre_file_id_tmp->m_file_path.charValue());
        } else {
            // aggre file
            aggre_file_id_tmp = std::make_unique<AggreMmapFile>(last_launch_file);
            
        }
    }
    m_is_stoping = false;
}

void RecordAggregation::ResetAggre() {
    if (m_is_stoping) {
        return;
    }
    std::vector<int> isfree_tmp;
    std::map<int, std::vector<block_flag>>::iterator iter;
    m_is_stoping = true;
    // 遍历所有分区
    for (iter = m_file_struct.begin(); iter != m_file_struct.end(); iter++) {
        for (int i = 0; i < iter->second.size(); i++) {
            isfree_tmp.push_back(int(iter->second[i].is_free - '0'));
        }
    }
    ReportAllDataWithFile(m_file_config, isfree_tmp, m_aggre_file_id);
    FreeFiles();
    NewAggreFile();
    m_is_stoping = false;
}

void RecordAggregation::ReportAllDataWithFile(std::map<int, int> &fileConfig_map, std::vector<int> &is_free_vec, std::unique_ptr<AggreMmapFile> &aggre_file_id_ptr) {
    if (aggre_file_id_ptr == nullptr || is_free_vec.empty() || is_free_vec.size() <= 0) {
        return;
    }
    int index = -1;
    int areaIndex = -1;
    for (auto& iter : fileConfig_map) {
        areaIndex++;
        for (int i = 0; i < iter.second; i++) {
            if (!is_free_vec[++index]) {
                int32_t fileOffset = CalculateFileOffset(areaIndex, i);
                std::string recordToPrepare = aggre_file_id_ptr->ReadAggreFile(fileOffset, iter.first);
                // 清空补充后缀
                recordToPrepare.erase(recordToPrepare.find_last_not_of(" ") + 1);
                RecordToPrepare(recordToPrepare);
            }
        }
    }
}

void RecordAggregation::RecordToPrepare(std::string &record) {
    if (record.empty()) return;
    Json::Value object;
    bool ret = hermas::ParseFromJson(record, object);
    if (!ret) {
        loge(AggregationTag, "To Prepare: Abandon record due to prasing failed. record = %s", record.c_str());
        return;
    };
    
    if (object.isObject() && object.isMember("class_name")) {
        std::string class_name = (object["class_name"]).asString();
        if (class_name.empty()) {
            object["sequence_code"] = "-1";
        } else {
            object["sequence_code"] = GlobalEnv::GetInstance().GetSequenceCodeGenerator()(class_name);
        }
    }
    
    if (callback != nullptr) {
        object.removeMember("class_name");
        std::string new_record = object.toStyledString();
        if (new_record.empty()) {
            return;
        } else {
            callback(new_record);
        }
    }
}

void RecordAggregation::Close() {
    FreeFiles(false);
}

void RecordAggregation::FreeFiles(bool is_delete) {
    if (m_aggre_file_id != nullptr) {
        m_aggre_file_id->CloseFile();
        if (is_delete) {
            RemoveFile(m_aggre_file_id->m_file_path);
        }
        m_aggre_file_id = nullptr;
    }
    
    if (m_aggre_config_file_id != nullptr) {
        m_aggre_config_file_id->CloseFile();
        if (is_delete) {
            RemoveFile(m_aggre_config_file_id->m_file_path);
        }
        m_aggre_config_file_id = nullptr;
    }
}

void RecordAggregation::EraseInvalidFiles(std::vector<FilePath>& files_path) {
    for (int i = (int)(files_path.size() - 1); i >= 0; i--) {
        bool is_config_file = IsConfigFile(files_path[i]);
        if (is_config_file && i > 0) {
            bool is_config_file_forward = IsConfigFile(files_path[i - 1]);
            if (is_config_file_forward) {
                // config file: source file can not be found forward, then delete this config file,i-1
                RemoveFile(GenAggreDirPath().Append(files_path[i]));
                files_path.erase(files_path.begin() + i);
            } else {
                bool is_matched = IsMatchedSourceAndConfigFiles(files_path[i - 1], files_path[i]);
                if (is_matched) {
                    // config file: matched source file can be found forward correctly, then i-2
                    i--;
                } else {
                    // config file: unmatched source file can be found forward, then delete this config file and unmatched source file, i - 2
                    RemoveFile(GenAggreDirPath().Append(files_path[i]));
                    RemoveFile(GenAggreDirPath().Append(files_path[i - 1]));
                    files_path.erase(files_path.begin() + i - 1, files_path.begin() + i);
                }
            }
            
        } else {
            // source file: invalid, then delete this source file, i - 1
            RemoveFile(GenAggreDirPath().Append(files_path[i]));
            files_path.erase(files_path.begin() + i);
        }
    }
}

bool RecordAggregation::IsConfigFile(const FilePath& file_path) {
    bool is_config_file = file_path.strValue().find("config") != std::string::npos;
    return is_config_file;
}

bool RecordAggregation::IsMatchedSourceAndConfigFiles(const FilePath& source_file_path, const FilePath& config_file_path) {
    return config_file_path.strValue().find(source_file_path.strValue()) != std::string::npos;
}
