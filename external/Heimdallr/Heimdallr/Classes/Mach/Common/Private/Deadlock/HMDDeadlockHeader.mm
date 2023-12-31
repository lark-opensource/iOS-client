//
//  HMDDeadlockHeader.mm
//  Pods
//
//  Created by wangyinhui on 2021/8/6.
//

#import "HMDDeadlockHeader.h"
#include "HMDDeadlockDiscover.hpp"
#include "HMDThreadLockTool.h"
#import "NSDictionary+HMDSafe.h"

#define MAX_DEADLOCK_NODE_LENTH 512


NSArray * fech_app_deadlock(BOOL *is_cycle, BOOL *is_main_thread_cycle) {
    NSMutableArray *lockGraph = [NSMutableArray new];
    *is_cycle = NO;
    *is_main_thread_cycle = NO;
    HMDDeadlockDiscover discover = HMDDeadlockDiscover();
    discover.fech_all_thread_lock();
    discover.fech_deadlock_cycle();
    if (discover.is_deadlock){
        *is_cycle = YES;
    }
    if (discover.is_main_thread_deadlock){
        *is_main_thread_cycle = YES;
    }
    if (!discover.lock_graph.empty()){
        for (vector<hmd_deadlocl_node>::iterator it = discover.lock_graph.begin(); it != discover.lock_graph.end(); it++){
            NSMutableDictionary *lockNode = [NSMutableDictionary new];
            [lockNode hmd_setObject:@(it->lock_type) forKey:@"lock_type"];
            [lockNode hmd_setObject:@(it->waiting_tid) forKey:@"waiting_tid"];
            [lockNode hmd_setObject:@(it->waiting_thread_name) forKey:@"waiting_thread_name"];
            [lockNode hmd_setObject:@(it->owner_tid) forKey:@"owner_tid"];
            [lockNode hmd_setObject:@(it->owner_thread_name) forKey:@"owner_thread_name"];
            [lockNode hmd_setObject:@(it->symbol_name) forKey:@"symbol_name"];
            [lockNode hmd_setObject:@(it->semaphore_name) forKey:@"semaphore_name"];
            [lockGraph addObject:lockNode];
        }
    }
    
    return [lockGraph copy];
}

char * fech_app_deadlock_str(bool * is_cycle, bool * is_main_thread_cycle) {
    HMDDeadlockDiscover discover = HMDDeadlockDiscover();
    *is_cycle = false;
    *is_main_thread_cycle = false;
    discover.fech_all_thread_lock();
    discover.fech_deadlock_cycle();
    if (discover.is_deadlock){
        *is_cycle = true;
    }
    if (discover.is_main_thread_deadlock){
        *is_main_thread_cycle = true;
    }
    int node_count = (int)discover.lock_graph.size();
    size_t buffer_size = MAX_DEADLOCK_NODE_LENTH * node_count +100;
    char * log = (char *)malloc(buffer_size);
    if (!log) return NULL;
    if (!discover.lock_graph.empty()){
        strncpy(log, "[", buffer_size-1);
        for (vector<hmd_deadlocl_node>::iterator it = discover.lock_graph.begin(); it != discover.lock_graph.end(); it++){
            char node_str[MAX_DEADLOCK_NODE_LENTH];
            snprintf(node_str, sizeof(node_str), "{\"lock_type\":\"%s\", \"waiting_tid\":\"%d\", \"waiting_thread_name\": \"%s\", \"owner_tid\":\"%d\", \"owner_thread_name\": \"%s\", \"symbol_name\": \"%s\", \"semaphore_name\": \"%llu\"}",
                    it->lock_type, it->waiting_tid, it->waiting_thread_name, it->owner_tid, it->owner_thread_name, it->symbol_name, it->semaphore_name);
            strncat(log, node_str, buffer_size - strlen(log)-1);
            node_count--;
            if (node_count > 0){
                strncat(log, ",", buffer_size - strlen(log)-1);
            }
        }
        strncat(log, "]", buffer_size - strlen(log)-1);
    }
    return log;
}
