//
//  search_service.cpp
//  Hermas
//
//  Created by 崔晓兵 on 28/1/2022.
//

#include "search_service.h"
#include "files_collect.h"
#include "file_service.h"
#include "files_collect.h"
#include "condition_node.h"
#include "search_filter.h"
#include "file_util.h"
#include "json_util.h"

namespace hermas {

using WeakUploadMap = WeakWrapper<std::map<std::string, std::shared_ptr<SearchService>>>;

std::vector<std::unique_ptr<SearchData>> SearchService::Search(const std::shared_ptr<hermas::ConditionNode>& condition) {
    std::vector<std::unique_ptr<SearchData>> result;
    
    // collect file
    auto global_local_path = GenLocalDirPath(m_env->GetModuleEnv());
    auto aid_path = global_local_path.Append(m_env->GetAid());
    auto files = GetFilesNameRecursively(aid_path);
    
    // build filter chain
    auto root_filter = std::make_unique<FileNameSearchFilter>(condition, m_env);
    
    // traverse
    int valid_count = 0;
    double total_size = 0;
    for (auto& file_path : files) {
        // intercept file with filter
        bool intercepted = root_filter->Intercept(file_path);
        if (intercepted) continue;
        
        // read file
        auto file_reader = GenerateFileReader(file_path);
        if (!file_reader) {
            logd("Hermas Search", "failed to open file: path = %s", file_path.strValue().c_str());
            continue;
        }
        
        std::unique_ptr<SearchData> search_data = std::make_unique<SearchData>();
        search_data->filename = file_path.strValue();
        ++valid_count;
        while (file_reader->HasNext()) {
            const std::string& data_line = file_reader->ReadNext();
            if (total_size + data_line.size() > GlobalEnv::GetInstance().GetMaxReportSize()) {
                int m_file_current_offset = file_reader->GetCurrentFileOffset();
                if (search_data->records.size() > 0) {
                    m_file_current_offset = (int)(file_reader->GetCurrentFileOffset() - data_line.length() - sizeof(int32_t));
                }
                file_reader->SetOffset(m_file_current_offset);
                break;
            } else {
                search_data->records.push_back(data_line);
            }
        }
        
        if (search_data->records.size() > 0) {
            result.push_back(std::move(search_data));
        }
        
        file_reader->CloseFile();
    }
    logd("Hermas Search", "search %d files of total files %d, find %d records", valid_count, files.size(), result.size());
    return result;
}

std::unique_ptr<MmapReadFile> SearchService::GenerateFileReader(FilePath& file_path) {
    std::unique_ptr<MmapReadFile> file_reader = std::make_unique<MmapReadFile>(file_path);
    bool file_opened = file_reader->OpenReadFile();
    if (!file_opened) return nullptr;
    if (file_reader->HasNext()) {
        std::string data_line = file_reader->ReadNext();
        file_reader->SyncOffsetAfterReadHead();
    }
    return file_reader;
}

}
