//
//  HMDDeadlockDiscover.hpp
//  Heimdallr
//
//  Created by wangyinhui on 2021/8/24.
//

#ifndef HMDDeadlockDiscover_hpp
#define HMDDeadlockDiscover_hpp

#include <stdio.h>
#include <vector>
#include <map>
#include <time.h>
#include <HMDThreadLockTool.h>

using namespace std;

class HMDDeadlockDiscover{
    map<uint64_t, thread_t> system_mach_thread_id_map; //系统线程id和进程线程id映射
    map<thread_t, size_t> index_mach_thread_id_map; //索引序号和进程线程id映射
    vector<hmd_deadlocl_node> simplify_lock_graph; //死锁环
//    map<thread_t, time_t> waiting_thread_map; //记录线程waiting状态的开始时间
    
public:
    vector<hmd_deadlocl_node> lock_graph; //线程之间的锁等待关系
    bool is_deadlock; //是否发生死锁
    bool is_main_thread_deadlock; //是否主线程死锁
    HMDDeadlockDiscover();
    ~HMDDeadlockDiscover();
    void fech_all_thread_lock();
    void fech_deadlock_cycle();
    
};

#endif /* HMDDeadlockDiscover_hpp */
