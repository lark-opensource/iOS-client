//
//  HMDDispatchNode.cpp
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/3/29.
//

#import "HMDDispatchNode.hpp"
#import <pthread/pthread.h>
#import <vector>
#import <string>
#import <memory>

#ifdef DEBUG
#define ELSE_DEBUG else __builtin_trap();
#define DEBUG_ASSERT(condtion) NSAssert((condtion),             \
        @"[FATAL ERROR] Please preserve current environment"    \
         " and contact Heimdallr developer ASAP.")
#else
#define ELSE_DEBUG
#define DEBUG_ASSERT(condtion)
#endif

static pthread_key_t HMDDispatchNodeListKey = 0;

static void destory_node_list_key_value(void *value) {
    if (value) {
        delete (std::vector<std::shared_ptr<HMDDispatchNode>> *)value;
    }
}

void init_dispatch_node(void) {
    if (HMDDispatchNodeListKey == 0) {
        pthread_key_create(&HMDDispatchNodeListKey, &destory_node_list_key_value);
    }
}

std::shared_ptr<HMDDispatchNode> current_thread_dispatch_node(void) {
    
    std::vector<std::shared_ptr<HMDDispatchNode>> *nodeList = (std::vector<std::shared_ptr<HMDDispatchNode>> *)pthread_getspecific(HMDDispatchNodeListKey);
    if (nodeList == NULL) {
        nodeList = new std::vector<std::shared_ptr<HMDDispatchNode>>;
        pthread_setspecific(HMDDispatchNodeListKey, nodeList);
    }
    if (nodeList->size() == 0) {
        std::shared_ptr<HMDDispatchNode> firstNode{new HMDDispatchNode{}};
        nodeList->push_back(firstNode);
    }
    return nodeList->back();
}

void update_current_thread_dispatch_node_list_by_copy(std::shared_ptr<HMDDispatchNode> origNode, const char *queueLabel) {
    std::shared_ptr<HMDDispatchNode> node{new HMDDispatchNode(*origNode)};
    
    if (queueLabel) {
        std::string s = std::string(queueLabel);
        node->queueList.push_back(s);
    }
    
    std::vector<std::shared_ptr<HMDDispatchNode>> *nodeList = (std::vector<std::shared_ptr<HMDDispatchNode>> *)pthread_getspecific(HMDDispatchNodeListKey);
    if (nodeList == NULL) {
        nodeList = new std::vector<std::shared_ptr<HMDDispatchNode>>;
        pthread_setspecific(HMDDispatchNodeListKey, nodeList);
    }
    nodeList->push_back(node);
}

void remove_current_thread_dispatch_node_list_last() {
    std::vector<std::shared_ptr<HMDDispatchNode>> *nodeList = (std::vector<std::shared_ptr<HMDDispatchNode>> *)pthread_getspecific(HMDDispatchNodeListKey);
    if (nodeList && nodeList->size() > 0) {
        nodeList->pop_back();
    } ELSE_DEBUG
}
