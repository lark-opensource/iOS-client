//
//  search_filter.cpp
//  Hermas
//
//  Created by 崔晓兵 on 16/2/2022.
//

#include "search_filter.h"
#include "condition_node.h"
#include "file_path.h"
#include "mmap_read_file.h"
#include "file_service_util.h"

namespace hermas {

void SearchFilter::SetNextFilter(const std::shared_ptr<SearchFilter>& next_filter) {
    m_next_filter = next_filter;
}

bool FileNameSearchFilter::Intercept(FilePath& file_path) {
    // extract the start time from file name
    int64_t timestamp = GetFileCreateTime(file_path);
    auto prune_con = m_condition->Pruning("timestamp");
    if (!prune_con) return false;
    bool ret = prune_con->Violate("timestamp", timestamp);
    if (ret) return true;
    return m_next_filter ? m_next_filter->Intercept(file_path) : false;
}

bool TimeSearchFilter::Intercept(FilePath& file_path) {
    // read the start and stop time from the bodyheader part in file
    auto times = GetFileStartAndStopTime(m_env->GetModuleEnv(), file_path);
    int64_t start_time = std::get<0>(times);
    int64_t stop_time = std::get<1>(times);
    auto prune_con = m_condition->Pruning("timestamp");
    if (!prune_con) return false;
    bool ret = prune_con->Violate("timestamp", {start_time, stop_time});
    if (ret) return true;
    return m_next_filter ? m_next_filter->Intercept(file_path) : false;
    
}

}
