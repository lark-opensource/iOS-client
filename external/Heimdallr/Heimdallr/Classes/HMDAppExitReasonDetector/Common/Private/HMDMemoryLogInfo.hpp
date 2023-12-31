//
//  HMDMemoryLogInfo.hpp
//  Heimdallr
//
//  Created by bytedance on 2023/1/12.
//

#ifndef HMDMemoryLogInfo_hpp
#define HMDMemoryLogInfo_hpp

#include <stdio.h>
#include <string>
#import "HMDFileWriter.hpp"
using namespace std;
using namespace HMDFileWriter;

namespace MemoryLog {
    class MemoryLogInfo {
        int m_timestamp;
        u_int32_t m_app_memory;
        u_int32_t m_used_memory;
        u_int64_t m_virtual_memory;
        int m_cpu_usage;
        const char *m_last_scene;
        
    public:
        void write_to(Writer &writer);
        MemoryLogInfo(int time_stamp, u_int32_t app_memory, u_int32_t used_memory, u_int64_t virtual_memory, int cpu_usage, const char *last_scene);
    };
}
#endif /* HMDMemoryLogInfo_hpp */
