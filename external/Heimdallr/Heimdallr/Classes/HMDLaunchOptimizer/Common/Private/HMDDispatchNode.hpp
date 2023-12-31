//
//  HMDDispatchNode.hpp
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/3/29.
//

#ifndef HMDDispatchNode_hpp
#define HMDDispatchNode_hpp

#import <vector>
#import <string>

struct HMDDispatchNode {
    std::vector<std::string> queueList = {};
};

extern void init_dispatch_node(void);
extern std::shared_ptr<HMDDispatchNode> current_thread_dispatch_node(void);
extern void update_current_thread_dispatch_node_list_by_copy(std::shared_ptr<HMDDispatchNode> enqueueNode, const char *queueLabel);
extern void remove_current_thread_dispatch_node_list_last();

#endif /* HMDDispatchNode_hpp */
