//
//  HMDDeadlockDiscover.cpp
//  Heimdallr
//
//  Created by wangyinhui on 2021/8/24.
//

#include "HMDDeadlockDiscover.hpp"
#include "hmd_thread_backtrace.h"
#include <set>

HMDDeadlockDiscover::HMDDeadlockDiscover(){
    is_deadlock = false;
    is_main_thread_deadlock = false;
}

HMDDeadlockDiscover::~HMDDeadlockDiscover(){
    lock_graph.clear();
    system_mach_thread_id_map.clear();
    simplify_lock_graph.clear();
}

void HMDDeadlockDiscover::fech_all_thread_lock(){
    thread_act_array_t thread_list;
    mach_msg_type_number_t origin_thread_count = 0;
    hmdbt_all_threads(&thread_list, &origin_thread_count);
    mach_msg_type_number_t thread_count = origin_thread_count;
    
    //记录系统thread_id与mach thread id的映射关系
    for (int i=0; i<thread_count; i++) {
        uint64_t system_tid = fetch_system_thread64_id(thread_list[i]);
        system_mach_thread_id_map[system_tid] = thread_list[i];
        index_mach_thread_id_map[thread_list[i]] = i;
        if (is_thread_waiting(thread_list[i])){
            hmd_deadlocl_node node = {0};
            node.waiting_thread_idx = i;
            node.waiting_tid =thread_list[i];
            int ret = fetch_thread_lock_info(&node);
            if (ret < 0){
                continue;
            }
            lock_graph.push_back(node);
        }
    }
    for (vector<hmd_deadlocl_node>::iterator it = lock_graph.begin(); it != lock_graph.end(); it++){
        if (it->owner_tid == 0 && it->owner_system_tid != 0){
            uint64_t stid = it->owner_system_tid;
            map<uint64_t, thread_t>::iterator smit = system_mach_thread_id_map.find(stid);
            if (smit != system_mach_thread_id_map.end()){
                it->owner_tid = smit->second;
            }
        }
        map<thread_t, size_t>::iterator imit = index_mach_thread_id_map.find(it->owner_tid);
        if (imit != index_mach_thread_id_map.end()) {
            it->owner_thread_idx = imit->second;
        }else{
            it->owner_thread_idx = 9999;
        }
        char waiting_thread_name[256] = {0};
        char owner_thread_name[256] = {0};
        hmdthread_getName(it->waiting_tid, waiting_thread_name, sizeof(waiting_thread_name));
        hmdthread_getName(it->owner_tid, owner_thread_name, sizeof(owner_thread_name));
        snprintf(it->waiting_thread_name, sizeof(waiting_thread_name), "Thread %lu name:  %s",
                 it->waiting_thread_idx, waiting_thread_name);
        snprintf(it->owner_thread_name, sizeof(owner_thread_name), "Thread %lu name:  %s",
                 it->owner_thread_idx, owner_thread_name);
    }
}



void HMDDeadlockDiscover::fech_deadlock_cycle(){
    if (lock_graph.empty()){
        return;
    }
    simplify_lock_graph = lock_graph; //保存移除入度为0的节点
    set<thread_t> main_associate_thrend_set; //对主线程相关联的线程进行染色
    main_associate_thrend_set.insert((unsigned int)hmdbt_main_thread);
    while (!simplify_lock_graph.empty()) {
        //统计各个线程的入度
        map<thread_t, int> nodeVertexmap;
        for (vector<hmd_deadlocl_node>::iterator it = simplify_lock_graph.begin(); it != simplify_lock_graph.end(); it++){
            if (it->owner_tid != 0){
                map<thread_t, int>::iterator mit = nodeVertexmap.find(it->owner_tid);
                if (mit != nodeVertexmap.end()){
                    nodeVertexmap[it->owner_tid] += 1;
                }else{
                    nodeVertexmap[it->owner_tid] = 1;
                }
            }
            if (it->waiting_tid != 0){
                map<thread_t, int>::iterator mit = nodeVertexmap.find(it->waiting_tid);
                if (mit == nodeVertexmap.end()){
                    nodeVertexmap[it->waiting_tid] = 0;
                }
            }
            //对关联主线程的节点染色
            if (main_associate_thrend_set.count(it->owner_tid) || main_associate_thrend_set.count(it->waiting_tid)){
                main_associate_thrend_set.insert(it->owner_tid);
                main_associate_thrend_set.insert(it->waiting_tid);
            }
        }
        bool is_contain_main = false;
        bool is_cycle = true;
        //所有节点入度为1，则存在环, 如果环中元素已被染色，则是主线程死锁
        for (map<thread_t, int>::iterator mit= nodeVertexmap.begin(); mit != nodeVertexmap.end(); mit++){
            if (main_associate_thrend_set.count(mit->first)){
                is_contain_main = true;
            }
            if (mit->second != 1){
                is_cycle = false;
                break;
            }
        }
        if (is_cycle){
            is_deadlock = true;
            if (is_contain_main){
                is_main_thread_deadlock = true;
            }
            return;
        }
        
        //移除入度为0的节点
        for (vector<hmd_deadlocl_node>::iterator it = simplify_lock_graph.begin(); it != simplify_lock_graph.end();){
            if (it->waiting_tid != 0){
                map<thread_t, int>::iterator mit = nodeVertexmap.find(it->waiting_tid);
                if (mit != nodeVertexmap.end()){
                    if (mit->second == 0){
                        it = simplify_lock_graph.erase(it);
                        continue;
                    }
                }
            }
            it++;
        }
    }
    
}


