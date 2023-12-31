//
//  memory_logging_event_config.hpp
//  AwemeInhouse
//
//  Created by zhufeng.llvm on 2022/1/10.
//

#ifndef memory_logging_event_config_hpp
#define memory_logging_event_config_hpp
#include <string>

void memory_event_enable_vmalloc(bool enable);
bool memory_event_is_enable_vmalloc();

void memory_event_get_name_one(std::string & name);
void memory_event_get_name_two(std::string & name);
void memory_event_get_name_three(std::string & name);

#endif /* memory_logging_event_config_hpp */
