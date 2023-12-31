//
//  migrate_service.h
//  AWEAnywhereArena
//
//  Created by 崔晓兵 on 7/6/2022.
//

#ifndef migrate_service_h
#define migrate_service_h

#include "env.h"
#include "service_factory.hpp"
#include "forward_protocol.h"
#include "network_service.h"

namespace hermas {

class MigrateService final {
public:
    MigrateService(const std::shared_ptr<ModuleEnv>& module_env);
    void Migrate();
    void CleanMigrateMark();
    
private:
    void ProcessSemifinishedFiles();
    void ProcessAggregateFiles();
    bool ProcessReadyFiles();
    void ProcessLocalFiles();
    
    std::vector<std::unique_ptr<RecordData>> PackageForUploading(std::vector<FilePath>& uploaded_file_paths, std::vector<std::string>& upload_aid_list);
    bool UploadRecordData(const std::vector<std::unique_ptr<RecordData>>& body, const std::vector<FilePath>& file_paths, std::string& aid_list);
    
private:
    std::shared_ptr<ModuleEnv> m_module_env;
    unsigned long m_file_current_offset = 0; //被切片的文件的offset地址，如果上传成功了就把这个offset值设置进去
    FilePath m_slices_file_path; //被切片的文件路径，如果上传失败，需要reset offset，不然会导致数据丢失
};

}

#endif /* migrate_service_h */
