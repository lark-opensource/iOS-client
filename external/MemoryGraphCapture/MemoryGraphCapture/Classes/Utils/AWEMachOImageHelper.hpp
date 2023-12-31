//
//  AWEMachOImageHelper.hpp
//  MemoryGraphDemo
//
//  Created by brent.shu on 2019/10/24.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#ifndef AWEMachOImageHelper_hpp
#define AWEMachOImageHelper_hpp

#import "AWEMemoryAllocator.hpp"

#import <mach-o/dyld.h>
#import <string>
#import <vector>
#import <unordered_map>
#import <unordered_set>

namespace MemoryGraph {

#ifdef __LP64__
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
#define LC_SEGMENT_T LC_SEGMENT_64
#else
typedef struct segment_command segment_command_t;
typedef struct section section_t;
#define LC_SEGMENT_T LC_SEGMENT
#endif

class ImageSection {
    ZONE_STRING m_sec_name;
public:
    std::pair<void *, uint32_t> m_range;
    ImageSection(const std::pair<void *, uint32_t> &range, const ZONE_STRING &name);
    
    const std::pair<void *, uint32_t> &range();
    const ZONE_STRING &name();
    bool  is_empty();
};

class ImageSegment {
    
    ZONE_VECTOR(ImageSection) m_sections;
    ZONE_STRING m_seg_name;
public:
    ImageSegment(const ZONE_STRING &img_name, const intptr_t slide, const segment_command_t * seg);
    
    const ZONE_VECTOR(ImageSection) &sections();
    const ZONE_STRING &name();
    bool  is_empty();
};

void getSections(const ZONE_STRING &seg_name, ZONE_VECTOR(ImageSegment) &output);

void getVtableMap(const std::function<void (uintptr_t, const ZONE_STRING &)> &callback);

void getValidCFTypeIDs(ZONE_SET(size_t) &valid_slts);

} // MemoryGraph

#endif /* AWEMachOImageHelper_hpp */
