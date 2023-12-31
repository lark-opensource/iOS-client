//
//  HMDMemoryLogInfo.cpp
//  Heimdallr
//
//  Created by bytedance on 2023/1/12.
//

#import "HMDMemoryLogInfo.hpp"
namespace MemoryLog {
    #define USAGE_BYTE 2
    #define VIRTUAL_BYTE 3

    MemoryLogInfo::MemoryLogInfo(int time_stamp, u_int32_t app_memory, u_int32_t used_memory, u_int64_t virtual_memory, int cpu_usage, const char* last_scene): m_timestamp(time_stamp), m_app_memory(app_memory), m_used_memory(used_memory), m_virtual_memory(virtual_memory), m_cpu_usage(cpu_usage), m_last_scene(last_scene)
    {
    }

    void MemoryLogInfo::write_to(Writer &writer) {
        size_t size = 4;
        writer.append(&size, 1);
        writer.append(&m_timestamp, size);
        
        size = USAGE_BYTE;
        writer.append(&size, 1);
        writer.append(&m_app_memory, size);
        
        size = USAGE_BYTE;
        writer.append(&size, 1);
        writer.append(&m_used_memory, size);
        
        size = VIRTUAL_BYTE;
        writer.append(&size, 1);
        writer.append(&m_virtual_memory, size);
        
        size = 1;
        writer.append(&size, 1);
        writer.append(&m_cpu_usage, size);
        
        size = strlen(m_last_scene);
        writer.append(&size, 1);
        writer.append(m_last_scene, size);
    }
}

