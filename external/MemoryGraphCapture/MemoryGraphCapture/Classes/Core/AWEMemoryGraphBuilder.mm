//
//  AWEMemoryGraphBuilder.cpp
//  MemoryGraphDemo
//
//  Created by brent.shu on 2019/10/28.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#import "AWEMemoryGraphBuilder.hpp"
#import "AWEMemoryGraphUtils.hpp"
#import "AWEMemoryClassItem.hpp"
#import "MemoryGraphVMHelper.hpp"
#import "AWEMemoryGraphTimeChecker.hpp"

#import <mach/vm_statistics.h>
#import <unordered_map>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <stdio.h>


namespace MemoryGraph {

NSString *META_PATH = @"meta.graph";
NSString *STR_PATH  = @"string.graph";
NSString *MAIN_PATH = @"main.graph";

const size_t META_FILE_SIZE = getpagesize();
const size_t STR_FILE_SIZE  = 1024 * 1024 * 10;
const size_t MAIN_FILE_SIZE = 1024 * 1024 * 250;
const size_t MAIN_FILE_DEFAULT_SIZE = 1024 * 1024 * 10;

const uint8_t GRAPH_VERSION = 5;

Cleaner::Cleaner(std::function<void ()> cleaner): m_cleaner(cleaner)
{
}

Cleaner::~Cleaner() {
    if (m_cleaner) {
        m_cleaner();
    }
}

Builder::Builder(const std::string &path, size_t max_file_size, std::function<ZONE_STRING (mach_port_t)> threadParser): m_err(), m_work_queue(),
m_meta_writer(nullptr), m_str_writer(nullptr), m_main_writer(nullptr), threadParser(threadParser) {
    if (!path.size()) {
        m_err = Error(ErrorType::LogicalError, "builder null path");
        return ;
    }
    
    auto ns_path = [NSString stringWithUTF8String:path.c_str()];
    if (![[NSFileManager defaultManager] fileExistsAtPath:ns_path]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:ns_path
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:nil]) {
            m_err = Error(ErrorType::CreateDirFailed, "builder");
            return ;
        }
    }
    
    m_meta_writer = new Writer([ns_path stringByAppendingPathComponent:META_PATH].UTF8String, META_FILE_SIZE, META_FILE_SIZE);
    m_err = m_meta_writer->err();
    if (!m_err.is_ok) {
        return ;
    }
    
    m_str_writer = new Writer([ns_path stringByAppendingPathComponent:STR_PATH].UTF8String, STR_FILE_SIZE, STR_FILE_SIZE);
    m_err = m_str_writer->err();
    if (!m_err.is_ok) {
        return ;
    }
    
    auto main_size = max_file_size ? max_file_size : MAIN_FILE_SIZE;
    m_main_writer = new Writer([ns_path stringByAppendingPathComponent:MAIN_PATH].UTF8String, MAIN_FILE_DEFAULT_SIZE, main_size);
    m_err = m_main_writer->err();
    if (!m_err.is_ok) {
        return ;
    }
}

Builder::~Builder() {
    if (m_meta_writer) delete m_meta_writer;
    if (m_str_writer) delete m_str_writer;
    if (m_main_writer) delete m_main_writer;
}

void Builder::build(NSTimeInterval timestamp, uint64_t footpint, ThreadSuspender &suspender, bool is_degrade_version) {
    if (is_degrade_version) { // only build instance info
        m_build_instance_info(timestamp, footpint, suspender);
    } else {
        m_build_standard_graph(timestamp, footpint, suspender);
    }
}

void
Builder::result(NSMutableDictionary *output) {
    
    auto data_generator = [&output](Writer *writer, NSString *key) {
        const void *buffer = nullptr;
        size_t size = 0;
        writer->content(buffer, size);
        
        if (size) {
            NSData *data = [NSData dataWithBytes:buffer length:size];
            [output setObject:[data base64EncodedStringWithOptions:0] forKey:key];
        }
    };
    
    data_generator(m_meta_writer, @"metaData");
    data_generator(m_str_writer, @"strData");
    data_generator(m_main_writer, @"mainData");
}

const Error &
Builder::err() {
    return m_err;
}

bool
Builder::sync() {
    bool state = true;
    
    state = m_meta_writer->end() && state;
    state = m_str_writer->end() && state;
    state = m_main_writer->end() && state;
    
    return state;
}

bool
Builder::end() {
    bool state = true;
    
    state = m_meta_writer->end() && state;
    state = m_str_writer->end() && state;
    state = m_main_writer->end() && state;
    
    return state;
}

bool
Builder::m_append_str(const ZONE_STRING &name, size_t index) {
    size_t size = name.size();
    bool state = true;
    state = state && m_str_writer->append(&index, 4);
    state = state && m_str_writer->append(&size, 2);
    if (size) {
        state = state && m_str_writer->append(name.c_str(), size);
    }
    
    if (!state) {
        m_err = m_str_writer->err();
    }
    return state;
}

bool
Builder::m_append_cls_name_array() {
    ennmulate_str([&](const ZONE_STRING &cls_name, int index, bool &stop) {
        if (!m_append_str(cls_name, index)) {
            stop = true;
        }
    });
    
    return m_err.is_ok;
}

void
Builder::m_build_standard_graph(NSTimeInterval timestamp, uint64_t footpint, ThreadSuspender &suspender) {
    Cleaner c([&](){
        m_work_queue.clear();
        ZONE_DEQUE(MemoryGraphNode) emptyQueue;
        m_work_queue.swap(emptyQueue); // free all related memory before return
    });
    
    auto node = MemoryGraphNode();
    
    // pass1 write meta info
    uint32_t nodes_count = 0;
    uint32_t edges_count = 0;
    
    GraphMeta graph_meta = {0, 0, GRAPH_VERSION, 0, 0, 0, 0, 0, false, false};
    if (!m_meta_writer->append(&graph_meta, sizeof(GraphMeta))) {
        m_err = m_meta_writer->err();
        return ;
    }
    
    // pass2 write nodes and edges
    auto child_handler = [this, &edges_count, &nodes_count](MemoryGraphNode *node, const ZONE_STRING &cus_cls, MemoryGraphEdge &edge, bool &stop) {
        if (cus_cls.size()){
            size_t index = increase_str_count();
            if (m_append_str(cus_cls, index)) {
                node->update_cls_idx(index);
            } else {
                stop = true;
            }
        }
        
        if(node) {
           MemoryNodeType type_of_node = node->node_type();
            if(type_of_node == MemoryNodeType::MemoryArea || type_of_node == MemoryNodeType::TransferToCache || type_of_node == MemoryNodeType::TransferToRwt) {
               m_work_queue.push_back(*node);
            }
        }
        
        // add edge
        edge.write_to(*m_main_writer);
        ++edges_count;
        if (!m_main_writer->err().is_ok) {
            m_err = m_main_writer->err();
            stop = true;
        }
    };
    
    // add user space && __data node
    m_work_queue.push_back(node);
    while (!m_work_queue.empty()) {
        auto node = m_work_queue.front();
        m_work_queue.pop_front();
        auto type = node.vm_info().type;
        if (type == VMInfoType::Process || type == VMInfoType::Segment || type == VMInfoType::ClassHelper) {
            node.find_child(child_handler);
        }
        node.write_to(*m_main_writer);
        ++nodes_count;
        if (!m_main_writer->err().is_ok) {
            m_err = m_main_writer->err();
            return ;
        }
    }
    if (MemoryGraphTimeChecker.isTimeOut) {
        MemoryGraphTimeChecker.errstr = "time out when analysis segment";
        return;
    }
    
    if (!m_err.is_ok) {
        return ;
    }
    
    bool needStop = false;
    // add stack node
    
    auto vh = vm_helper();
    if (!vh) {
        m_err = Error(ErrorType::LogicalError, "null vm helper");
        return ;
    }
    vh->enumeratStack([&](StackInfo &stack_info) {
        if (needStop) {
            return ;
        }

        if (stack_info.in_use_size) {
            auto node = MemoryGraphNode(stack_info.ptr, (uintptr_t)stack_info.sp - (uintptr_t)stack_info.ptr, {stack_info.in_use_size, (VMInfoType)VM_MEMORY_STACK});
            node.find_child(child_handler);
            if (MemoryGraphTimeChecker.isTimeOut) {
                needStop = true;
            }
        }
        
        auto node = MemoryGraphNode(stack_info.ptr, {(uint32_t)stack_info.dirty_size, (VMInfoType)VM_MEMORY_STACK});
        
        MemoryGraphVMHelper *helper = vm_helper();
        auto item = helper->m_stack_thread_map.find((uintptr_t)stack_info.ptr);
        if (item != helper->m_stack_thread_map.end()) {
            if (threadParser) {
                ZONE_STRING threadName = threadParser(item->second);
                char buffer [33] = {0};
                sprintf(buffer, "%u", stack_info.size/1024);
                ZONE_STRING threadSize = buffer;
                if (threadName.length() > 0) {
                    int index = increase_str_count();
                    if (m_append_str("VM: Stack-"+threadSize+"-"+threadName, index)) {
                        node.update_cls_idx(index);
                    }
                } else {
                    int index = increase_str_count();
                    if (m_append_str("VM: Stack-"+threadSize, index)) {
                        node.update_cls_idx(index);
                    }
                }
            }
        } else {
            char buffer [33] = {0};
            sprintf(buffer, "%u", stack_info.size/1024);
            ZONE_STRING threadSize = buffer;
            int index = increase_str_count();
            if (m_append_str("VM: Stack-"+threadSize, index)) {
                node.update_cls_idx(index);
            }
        }
        
        
        node.write_to(*m_main_writer);
        ++nodes_count;
        if (!m_main_writer->err().is_ok) {
            m_err = m_main_writer->err();
            needStop = true;
        }
    });
    
    if (!m_err.is_ok) {
        return ;
    }
    if (MemoryGraphTimeChecker.isTimeOut) {
        MemoryGraphTimeChecker.errstr = "time out when analysis stack";
        return;
    }
    
    // add vm node
    vh->enumeratVm([this, &nodes_count, &needStop, &child_handler](const void *ptr, VMInfo &vm_info) {
        if (needStop || vm_info.type == VM_MEMORY_STACK) { // stack is enumerated before
            return ;
        }
        
        Class cls = vm_info.type == VMInfoType::Heap ? cls_of_ptr((void *)ptr, vm_info.size) : nil;
        auto node = cls ? MemoryGraphNode((void *)ptr, vm_info, cls) : MemoryGraphNode((void *)ptr, vm_info);
        node.write_to(*m_main_writer);
        if (vm_info.type >= VMInfoType::Heap) {
            node.find_child(child_handler);
            if (MemoryGraphTimeChecker.isTimeOut) {
                needStop = true;
            }
        }
        ++nodes_count;
        if (!m_main_writer->err().is_ok) {
            m_err = m_main_writer->err();
            needStop = true;
        }
    });
    
    if (!m_err.is_ok) {
        return ;
    }
    
    if (MemoryGraphTimeChecker.isTimeOut) {
        return;
    }

    // resume before append cls avoid runtime deadlock
    suspender.resume();
    // at last, append class info
    m_append_cls_name_array();
    
    if (m_err.is_ok) {
        // update meta info
        GraphMeta graph_meta =
            {footpint, timestamp, GRAPH_VERSION, nodes_count, edges_count, (uint32_t)str_count(), (uint32_t)m_str_writer->size(),
            (uint32_t)m_main_writer->size(), true, false};
        if (!m_meta_writer->write(&graph_meta, 0, sizeof(GraphMeta))) {
            m_err = m_meta_writer->err();
        }
    }
}

void
Builder::m_build_instance_info(NSTimeInterval timestamp, uint64_t footpint, ThreadSuspender &suspender) {
    // pass1 write meta info
    uint32_t nodes_count = 0;
    
    GraphMeta graph_meta = {0, 0, GRAPH_VERSION, 0, 0, 0, 0, 0, false, true};
    if (!m_meta_writer->append(&graph_meta, sizeof(GraphMeta))) {
        m_err = m_meta_writer->err();
        return ;
    }
    
    bool enable_autorelease_pool_identify = false;
    if(@available(iOS 12.0, *)) {
        enable_autorelease_pool_identify = true;
    }
    
    auto hash_table =
    std::unordered_map<MemoryClassItemKey, MemoryClassItem, MemoryClassItemKeyHasher, std::equal_to<MemoryClassItemKey>,
    ZoneAllocator<std::pair<const MemoryClassItemKey, MemoryClassItem>>>();
    
    ZONE_HASH(uintptr_t, ZONE_STRING) thread_name_table; /* 存储VM：Stack首地址和线程符号化信息*/
    ZONE_HASH(uintptr_t, ZONE_STRING) pthread_name_table; /* 存储AutoreleasePoolPage+24偏移处的pthread_t地址，和VM：Stack首地址不一致，但是会落在VM：Stack范围内*/
    auto m_add_item = [&hash_table, &thread_name_table, &pthread_name_table, enable_autorelease_pool_identify](const VMInfo &info, void *ptr) {
        Class cls = nil;
        bool autorelease_pool_page_identified = false;
        ZONE_STRING node_name = ZONE_STRING("");
        if (info.type == VMInfoType::Heap) {
            if (enable_autorelease_pool_identify && is_autorelease_pool_page(ptr, info.size)) {
                autorelease_pool_page_identified = true;
                // 获得AutoreleasePoolPage偏移24字节的pthread地址
                uintptr_t pthread = *(uintptr_t*)((uint8_t*)ptr + 24);
                auto it = pthread_name_table.find(pthread);
                ZONE_STRING thread_name = ZONE_STRING("");
                if (it == pthread_name_table.end()) {
                    uintptr_t stack_address = vm_helper()->stackWhichContainsAddress(pthread);
                    auto it = thread_name_table.find(stack_address);
                    if (it != thread_name_table.end()) {
                        pthread_name_table.emplace((uintptr_t)pthread, it->second);
                        thread_name = it->second;
                    }
                }else {
                    thread_name = it->second;
                }
                if (thread_name.length() > 0) {
                    node_name = ZONE_STRING("AutoreleasePoolPage-") + thread_name;
                }else {
                    node_name = ZONE_STRING("AutoreleasePoolPage");
                }
            }else {
                cls = cls_of_ptr(ptr, info.size);
            }
        }
        auto key = MemoryClassItemKey(ptr, cls, info);
        key.set_name(node_name);
        auto it = hash_table.find(key);
        if (it == hash_table.end()) {
            MemoryClassItem classItem = MemoryClassItem(info, cls, ptr);
            classItem.set_name(node_name);
            hash_table.insert({key, classItem});
        } else {
            it->second.add_count();
        }
    };
    
    auto dec2hex = [](uintptr_t i){
        std::stringstream ioss; //定义字符串流
        ZONE_STRING s_temp; //存放转化后字符
        ioss << std::resetiosflags(std::ios::uppercase) << std::hex << i; //以十六制(小写)形式输出
        //ioss << setiosflags(ios::uppercase) << hex << i; //以十六制(大写)形式输出
        ioss >> s_temp;
        return s_temp;
    };
    
    auto m_add_stack_item = [&hash_table,&thread_name_table,this, &dec2hex](const VMInfo &info, void *ptr) {
        auto key = MemoryClassItemKey(ptr, nil, info);
        MemoryGraphVMHelper *helper = vm_helper();
        thread_t port = 0;
        ZONE_STRING threadName;
        auto item = helper->m_stack_thread_map.find((uintptr_t)ptr);
        if (item != helper->m_stack_thread_map.end()) {
            port = item->second;
        }
        if(threadParser) {
            threadName = threadParser(port);
            if (threadName.length() > 0) {
                key.set_name(threadName);
                thread_name_table.insert({(uintptr_t)ptr, threadName+ZONE_STRING("- 0x")+dec2hex((uintptr_t)ptr)});
            }
        }
        auto it = hash_table.find(key);
        if (it == hash_table.end()) {
            MemoryClassItem classItem = MemoryClassItem(info, nil, ptr);
            if (threadName.length() > 0) {
                ZONE_STRING stackName = "VM: Stack-"+threadName;
                classItem.set_name(stackName);
            }
            hash_table.insert({key, classItem});
        } else {
            it->second.add_count();
        }
    };
    
    auto vh = vm_helper();
    if (!vh) {
        m_err = Error(ErrorType::LogicalError, "null vm helper");
        return ;
    }
    
    // add stack node
    vh->enumeratStack([&](StackInfo &stack_info) {
        VMInfo info = {stack_info.size,(VMInfoType)VM_MEMORY_STACK};
        m_add_stack_item(info, stack_info.ptr);
    });
    
    // add vm node
    vh->enumeratVm([&m_add_item](void *ptr, VMInfo &vm_info) {
        if (vm_info.type == VM_MEMORY_STACK) { // stack is enumerated before
            return ;
        }
        m_add_item(vm_info, ptr);
    });
    
    // before write, resume first, avoid runtime lock
    suspender.resume();
    
    for (auto it = hash_table.begin(); it != hash_table.end(); ++it) {
        it->second.write_to(*m_main_writer);
        if (!m_main_writer->err().is_ok) {
            m_err = m_main_writer->err();
            return ;
        }
    }
    
    if (m_err.is_ok) {
        // update meta info
        GraphMeta graph_meta =
            {footpint, timestamp, GRAPH_VERSION, nodes_count, 0, (uint32_t)str_count(), (uint32_t)m_str_writer->size(),
            (uint32_t)m_main_writer->size(), true, true};
        if (!m_meta_writer->write(&graph_meta, 0, sizeof(GraphMeta))) {
            m_err = m_meta_writer->err();
        }
    }
}

} // MemoryGraph
