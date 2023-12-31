//
//  record_aggregation.h
//  Hermas
//
//  Created by liuhan on 2022/1/17.
//

#ifndef record_aggregation_h
#define record_aggregation_h

#include <string>
#include <map>
#include <vector>
#include <functional>
#include "constants.h"
#include "aggre_mmap_file.h"
namespace hermas {

struct block_flag
{
    char is_free;
    uint16_t aggre_count;
    std::string aggre_key;
};

class RecordAggregation {
public:
    RecordAggregation(std::string& app_id, std::string& module_name, FilePath& root_path, int file_size, std::map<int, int>& file_config, std::map<std::string, std::vector<std::string>>& aggre_into_max);
    ~RecordAggregation() = default;
    
public:
    void DoRecordAggregation(std::string& record);
    std::function<void(std::string&)> callback;
    void StopAggregation(bool isLaunchStop = false);
    void LaunchReportForAggre();
    void ResetAggre();
    void Close();
    void FreeFiles(bool is_delete = true);

private:
    bool m_is_stoping;
    std::string m_app_id;
    FilePath m_root_path;
    std::string m_module_name;
    int m_file_size = 1024 * 1024;
    std::map<int, int>m_file_config = {{1024, 1024}};
    std::unique_ptr<AggreMmapFile> m_aggre_file_id;
    std::unique_ptr<AggreMmapFile> m_aggre_config_file_id;
    std::map<int, std::vector<block_flag>> m_file_struct;
    std::map<std::string, std::vector<std::string>> m_aggre_into_max;
    
    void VertifyConfigIsValid(int file_size, const std::map<int, int>& file_config);
    void NewAggreFile();
    void GenFileStrust();
    const FilePath GenAggreDirPath();

    std::string AggreRecord(std::string& old_record, std::string& new_record);
    std::string GenAggreKey(std::string& record);
    int32_t CalculateFileOffset(int area_index, int block_index);
    void RecordToPrepare(std::string& record);
    
    void InitAggreConfigFile(const FilePath& file_path);
    void ReportAllDataWithFile(std::map<int, int>& fileConfig_map, std::vector<int>& is_free_vec, std::unique_ptr<AggreMmapFile>& aggre_file_id_ptr);
    void EraseInvalidFiles(std::vector<FilePath>& files_path);
    bool IsConfigFile(const FilePath& file_path);
    bool IsMatchedSourceAndConfigFiles(const FilePath& source_file_path, const FilePath& config_file_path);
};

} //namespace hermas

#endif /* record_aggregation_h */
