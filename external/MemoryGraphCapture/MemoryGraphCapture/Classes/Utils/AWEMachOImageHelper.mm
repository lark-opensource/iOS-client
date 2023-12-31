//
//  AWEMachOImageHelper.cpp
//  MemoryGraphDemo
//
//  Created by brent.shu on 2019/10/24.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#import "AWEMachOImageHelper.hpp"

#import <Foundation/Foundation.h>
#import <cxxabi.h>

#define LEVEL_TYPEINFO 1
#define LEVEL_VTABLE   2
#define IS_VALID_CHAR(c) (isalnum(c) || (c) == '_' || (c) == '$')

namespace MemoryGraph {

using USED_TARGET_TYPE = std::pair<uintptr_t, size_t>;
using USED_SECS_TYPE = std::pair<const char *, ZONE_VECTOR(const char *)>;

uintptr_t first_cmd_after_header(const struct mach_header* const header) {
    switch(header->magic)
    {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);
        default:
            // Header is corrupt
            return 0;
    }
}

ImageSection::ImageSection(const std::pair<void *, uint32_t> &range, const ZONE_STRING &name):
m_range(range), m_sec_name(name) {
}

const std::pair<void *, uint32_t> &
ImageSection::range() {
    return m_range;
}

const ZONE_STRING &
ImageSection::name() {
    return m_sec_name;
}

bool
ImageSection::is_empty() {
    return m_range.second == 0;
}

ImageSegment::ImageSegment(const ZONE_STRING &img_name, const intptr_t slide, const segment_command_t * seg) {
    m_seg_name = img_name + ZONE_STRING(" ") + seg->segname;
    const section_t *sec = (section_t *)(seg + 1); // section following seg;
    for (uint32_t sec_idx = 0; sec_idx < seg->nsects; ++sec_idx) {
        void *addr = (void *)(sec->addr + slide);
        m_sections.push_back(ImageSection({addr, sec->size}, sec->sectname));
        ++sec;
    }
}

const ZONE_VECTOR(ImageSection) &
ImageSegment::sections() {
    return m_sections;
}

const ZONE_STRING &
ImageSegment::name() {
    return m_seg_name;
}

bool
ImageSegment::is_empty() {
    return m_sections.size() == 0;
}

void getSections(const ZONE_STRING &seg_name, ZONE_VECTOR(ImageSegment) &output) {
    uint32_t imgs = _dyld_image_count();
    for (uint32_t img = 0; img < imgs; ++img) {
        auto header = _dyld_get_image_header(img);
        auto slide = _dyld_get_image_vmaddr_slide(img);
        auto img_path = ZONE_STRING(_dyld_get_image_name(img) ?: "");
        auto begin = img_path.find_last_of("/");
        auto img_name = begin + 1 < img_path.size() ? img_path.substr(begin + 1) : "";
        
        if(header != NULL) {
            uintptr_t cmd_ptr = first_cmd_after_header(header);
            if(cmd_ptr == 0) {
                return;
            }
            
            for(uint32_t i_cmd = 0; i_cmd < header->ncmds; i_cmd++) {
                const struct load_command *loadCmd = (struct load_command *)cmd_ptr;
                if (loadCmd->cmd == LC_SEGMENT_T) {
                    const segment_command_t *seg = (segment_command_t *)cmd_ptr;
                    if (strncmp(seg->segname, seg_name.c_str(), seg_name.size()) == 0) {
                        ImageSegment s(img_name, slide, seg);
                        if (!s.is_empty()) {
                            output.push_back(std::move(s));
                        }
                    }
                }
                cmd_ptr += loadCmd->cmdsize;
            }
        }
    }
}

static void getVtableMapOfImage(uint32_t img, const std::function<void (uintptr_t, const ZONE_STRING &)> &callback) {
    auto header = _dyld_get_image_header(img);
    if (header == NULL) {
        return;
    }
    
    auto slide = _dyld_get_image_vmaddr_slide(img);
    ZONE_VECTOR(USED_TARGET_TYPE) rtti_secs;
    ZONE_VECTOR(USED_TARGET_TYPE) rtti_str_secs;
    void *ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_HASH(uintptr_t, const ZONE_STRING)));
    ZONE_HASH(uintptr_t, const ZONE_STRING) *mapTmp = new(ptr)ZONE_HASH(uintptr_t, const ZONE_STRING);
    std::unique_ptr<ZONE_HASH(uintptr_t, const ZONE_STRING)> map (mapTmp);
    uintptr_t ptr_mask = 0;
    
    ZONE_VECTOR(USED_SECS_TYPE) rtti_sec_names = {
        {"__DATA_CONST", {"__const"}},
        {SEG_DATA, {"__const", "__data"}}
    };
    ZONE_VECTOR(USED_SECS_TYPE) rtti_str_sec_names = {
        {SEG_TEXT, {"__const"}},
        {"__RODATA", {"__const"}}
    };
    
    // pass1: get symbol_cmd/const sections;
    {
        uintptr_t cmd_ptr = first_cmd_after_header(header);
        if(cmd_ptr == 0) {
            return;
        }
        for(uint32_t i_cmd = 0; i_cmd < header->ncmds; i_cmd++) {
            const struct load_command *loadCmd = (struct load_command *)cmd_ptr;
            if (loadCmd->cmd == LC_SEGMENT_T) {
                const segment_command_t *seg = (segment_command_t *)cmd_ptr;
                auto push = [&](ZONE_VECTOR(USED_SECS_TYPE) &sec_names, ZONE_VECTOR(USED_TARGET_TYPE) &secs) {
                    for (auto it = sec_names.begin(); it != sec_names.end(); ++it) {
                        if (strcmp(seg->segname, it->first) == 0) {
                            const section_t *sec = (section_t *)(seg + 1);
                            for (uint32_t sec_idx = 0; sec_idx < seg->nsects; ++sec_idx, ++sec) {
                                for (auto target_sec = it->second.begin(); target_sec != it->second.end(); ++target_sec) {
                                    if (strcmp(sec->sectname, *target_sec) == 0) {
                                        secs.push_back({(uintptr_t)(sec->addr + slide), sec->size});
                                    }
                                }
                            }
                        }
                    }
                };
                push(rtti_sec_names, rtti_secs);
                push(rtti_str_sec_names, rtti_str_secs);
            }
            cmd_ptr += loadCmd->cmdsize;
        }
    }
    
    // pass2 typeinfo name ptr
    {
        for (auto it = rtti_str_secs.begin(); it != rtti_str_secs.end(); ++it) {
            size_t tail, head = 0;
            const char *base = (const char *)it->first;
            while (head < it->second) {
                for (tail = head; tail < it->second; ++tail) {
                    if (base[tail] == '\0') break;
                }
                if (tail == it->second) break;
                if (tail - head >= 3) {
                    auto i = tail - 1;
                    for (; i >= head && IS_VALID_CHAR(base[i]); --i) {
                    }
                    ++i;
                    
                    if (tail - i >= 3) {
                        auto str = (const char *)(base + i);
                        size_t size = 16;
                        int status = 0;
                        char *demangledTmp = (char*)malloc_zone_malloc(g_malloc_zone(), size);
                        char *demangled = abi::__cxa_demangle(str, demangledTmp, &size, &status);
                        
                        if (status == 0 && size > 0) {
                            ptr_mask |= (uintptr_t)str;
                            map->insert({(uintptr_t)str, demangled});
                        }
                    }
                }
                head = tail + 1;
            }
        }
        ptr_mask = ~ptr_mask;
    }
    
    auto back_tracking = [&](int level) {
        void *ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_HASH(uintptr_t, const ZONE_STRING)));
        auto local_map = new(ptr) ZONE_HASH(uintptr_t, const ZONE_STRING);
        uintptr_t local_ptr_mask = 0;
        for (auto sec = rtti_secs.begin(); sec != rtti_secs.end(); ++sec) {
            auto step = sizeof(uintptr_t);
            for (auto offset = 0; offset + step <= sec->second; offset += step) {
                auto addr = sec->first + offset;
#if defined(__LP64__)
                typedef uintptr_t __type_name_t;
                static const unsigned long __non_unique_rtti_bit_mask = (1ULL <<((__CHAR_BIT__ * sizeof(__type_name_t))-1));
                auto value = LEVEL_TYPEINFO == level ? (*((uintptr_t *)addr)) & ~__non_unique_rtti_bit_mask : (*((uintptr_t *)addr));//@note:最高位置0
#else
                auto value = *((uintptr_t *)addr);
#endif
                if ((value & ptr_mask) != 0) continue;
                auto it = map->find(value);
                if (it != map->end()) {
                    auto fixed_addr = LEVEL_TYPEINFO == level ? addr - sizeof(uintptr_t) : addr + sizeof(uintptr_t);
                    local_map->insert({fixed_addr, std::move(it->second)});
                    map->erase(it);
                    local_ptr_mask |= fixed_addr;
                }
            }
        }
        ptr_mask = ~local_ptr_mask;
        map.reset(local_map);
    };
    
    // pass3 find typeinfo ptr
    back_tracking(LEVEL_TYPEINFO);
    
    // pass4 find vtable ptr
    back_tracking(LEVEL_VTABLE);
    
    // pass5 fetch result
    for (auto it = map->begin(); it != map->end(); ++it) {
        callback(it->first, it->second);
    }
}

void getVtableMap(const std::function<void (uintptr_t, const ZONE_STRING &)> &callback) {
    uint32_t imgs = _dyld_image_count();
    for (uint32_t img = 0; img < imgs; ++img) {
        getVtableMapOfImage(img, callback);
    }
}

void getValidCFTypeIDs(ZONE_SET(size_t) &valid_slts) {
    // pass1 found target img
    uint32_t imgs = _dyld_image_count();
    uint32_t founded_img = -1;
    for (uint32_t img = 0; img < imgs; ++img) {
        auto name = _dyld_get_image_name(img);
        if (name && strlen(name) >= strlen("CoreFoundation") && strstr(name, "CoreFoundation")) {
            founded_img = img;
            break;
        }
    }
    
    if (founded_img == -1) {
        return ;
    }
    
    ZONE_VECTOR(USED_TARGET_TYPE) target_secs;
    ZONE_VECTOR(USED_SECS_TYPE) sec_names = {
        {"__DATA_DIRTY", {"__data", "__common"}},
    };
    
    ZONE_VECTOR(USED_TARGET_TYPE) const_str_secs;
    ZONE_VECTOR(USED_SECS_TYPE) const_str_sec_names = {
        {SEG_TEXT, {"__cstring"}}
    };
    
    ZONE_VECTOR(USED_TARGET_TYPE) data_const_secs;
    ZONE_VECTOR(USED_SECS_TYPE) data_const_sec_names = {
        {"__DATA_CONST", {"__const"}},
        {"__AUTH_CONST", {"__const"}}
    };
    
    // pass2 prepare segments
    {
        auto slide = _dyld_get_image_vmaddr_slide(founded_img);
        auto header = _dyld_get_image_header(founded_img);
        uintptr_t cmd_ptr = first_cmd_after_header(header);
        if(cmd_ptr == 0) {
            return ;
        }
        for(uint32_t i_cmd = 0; i_cmd < header->ncmds; i_cmd++) {
            const struct load_command *loadCmd = (struct load_command *)cmd_ptr;
            if (loadCmd->cmd == LC_SEGMENT_T) {
                const segment_command_t *seg = (segment_command_t *)cmd_ptr;
                auto push = [&](ZONE_VECTOR(USED_SECS_TYPE) &sec_names, ZONE_VECTOR(USED_TARGET_TYPE) &secs) {
                    for (auto it = sec_names.begin(); it != sec_names.end(); ++it) {
                        if (strcmp(seg->segname, it->first) == 0) {
                            const section_t *sec = (section_t *)(seg + 1);
                            for (uint32_t sec_idx = 0; sec_idx < seg->nsects; ++sec_idx, ++sec) {
                                for (auto target_sec = it->second.begin(); target_sec != it->second.end(); ++target_sec) {
                                    if (strcmp(sec->sectname, *target_sec) == 0) {
                                        secs.push_back({(uintptr_t)(sec->addr + slide), sec->size});
                                    }
                                }
                            }
                        }
                    }
                };
                push(sec_names, target_secs);
                push(const_str_sec_names, const_str_secs);
                push(data_const_sec_names, data_const_secs);
            }
            cmd_ptr += loadCmd->cmdsize;
        }
    }
    
    // pass3 cf name ptr
    uintptr_t cf_0 = 0;
    uintptr_t cf_1 = 0;
    size_t    cf_0_idx = CFStringGetTypeID();
    size_t    cf_1_idx = CFDictionaryGetTypeID();
    {
        for (auto it = const_str_secs.begin(); it != const_str_secs.end(); ++it) {
            size_t tail, head = 0;
            const char *base = (const char *)it->first;
            while (head < it->second) {
                for (tail = head; tail < it->second; ++tail) {
                    if (base[tail] == '\0') break;
                }
                if (tail == it->second) break;
                if (tail - head >= 8) {
                    auto i = tail - 1;
                    for (; i >= head && IS_VALID_CHAR(base[i]); --i) {
                    }
                    ++i;
                    
                    if (tail - i >= 8) {
                        auto str = (const char *)(base + i);
                        if (strcmp(str, "CFString") == 0) {
                            cf_0 = (uintptr_t)str;
                        }
                        if (strcmp(str, "CFDictionary") == 0) {
                            cf_1 = (uintptr_t)str;
                        }
                        
                        if (cf_0 && cf_1) {
                            break;
                        }
                    }
                }
                head = tail + 1;
            }
        }
    }
    
    // pass4 back tracking
    auto back_tracking = [](ZONE_VECTOR(USED_TARGET_TYPE) &secs, uintptr_t target) -> std::pair<uintptr_t, std::pair<uintptr_t, size_t>> {
        for (auto sec = secs.begin(); sec != secs.end(); ++sec) {
            auto step = sizeof(uintptr_t);
            for (auto offset = 0; offset + step <= sec->second; offset += step) {
                auto addr = sec->first + offset;
                auto value = *((uintptr_t *)addr);
                if (value == target) {
                    return {addr, {sec->first, sec->second}};
                }
            }
        }
        return {0, {0, 0}};
    };
    
    cf_0 = back_tracking(data_const_secs, cf_0).first;
    cf_1 = back_tracking(data_const_secs, cf_1).first;
    
    if (cf_0) {
        cf_0 = cf_0 - sizeof(uintptr_t);
    }
    
    if (cf_1) {
        cf_1 = cf_1 - sizeof(uintptr_t);
    }
    
    auto cf_0_r = back_tracking(target_secs, cf_0);
    auto cf_1_r = back_tracking(target_secs, cf_1);
    
    auto cf_0_slt = cf_0_r.first;
    auto cf_1_slt = cf_1_r.first;
    
    // pass5 verification legality than set valid slts
    if (cf_0_slt && cf_1_slt &&
        (cf_0_r.second == cf_1_r.second) &&
        (cf_1_slt - cf_0_slt == ((cf_1_idx - cf_0_idx) * sizeof(uintptr_t)))) {
        auto class_table_entry = (uintptr_t *)(cf_0_slt - sizeof(uintptr_t) * cf_0_idx);
        if ((uintptr_t)class_table_entry >= cf_0_r.second.first &&
            (uintptr_t)class_table_entry + 1024 <= cf_0_r.second.first + cf_0_r.second.second) {
            for (auto i = 0; i < 1024; ++i) {
                if (class_table_entry[i] != 0) {
                    valid_slts.insert(i);
                }
            }
        }
    }
}

} // MemoryGraph
