//
//  AWEMemoryGraphBuilder.hpp
//  MemoryGraphDemo
//
//  Created by brent.shu on 2019/10/28.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#ifndef AWEMemoryGraphBuilder_hpp
#define AWEMemoryGraphBuilder_hpp

#import "AWEMemoryGraphNode.hpp"
#import "AWEMemoryAllocator.hpp"
#import "AWEMemoryGraphWriter.hpp"
#import "AWEMemoryGraphErrorDefines.hpp"
#import "ThreadManager.hpp"

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <string>
#import <deque>

namespace MemoryGraph {

FOUNDATION_EXPORT NSString *META_PATH;
FOUNDATION_EXPORT NSString *STR_PATH;
FOUNDATION_EXPORT NSString *MAIN_PATH;

enum Arch: uint8_t {
    Arch64 = 0,
    Arch32 = 1
};

struct GraphMeta {
    uint64_t       footprint;
    NSTimeInterval timestamp;
    uint8_t        version;
    uint32_t       nodecount;
    uint32_t       edgecount;
    uint32_t       strcount;
    uint32_t       str_file_real_size;
    uint32_t       main_file_real_size;
    bool           is_valid;
    bool           is_degrade_version;
};

class Cleaner {
    std::function<void ()> m_cleaner;
public:
    Cleaner(std::function<void ()> cleaner);
    ~Cleaner();
};

class Builder {
    ZONE_DEQUE(MemoryGraphNode) m_work_queue;
    Writer *m_meta_writer;
    Writer *m_str_writer;
    Writer *m_main_writer;
    
    Error m_err;
    
    std::function<ZONE_STRING (thread_t)> threadParser;
    
    bool m_append_str(const ZONE_STRING &name, size_t index);
    bool m_append_cls_name_array();
    void m_build_standard_graph(NSTimeInterval timestamp, uint64_t footpint, ThreadSuspender &suspender);
    void m_build_instance_info(NSTimeInterval timestamp, uint64_t footpint, ThreadSuspender &suspender);
public:
    Builder(const std::string &path, size_t max_file_size, std::function<ZONE_STRING (mach_port_t)> threadParser);
    ~Builder();
    
    const Error &err();
    
    void build(NSTimeInterval timestamp, uint64_t footpint, ThreadSuspender &suspender, bool is_degrade_version);
    
    bool sync();
    
    bool end();
    
    void result(NSMutableDictionary *output);
};

} // MemoryGraph

#endif /* AWEMemoryGraphBuilder_hpp */
