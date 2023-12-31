//
//  memory_logging_event_config.cpp
//  AwemeInhouse
//
//  Created by zhufeng.llvm on 2022/1/10.
//

#include "memory_logging_event_config.h"
#include <string>
#include <vector>
#include <unordered_map>


// global config
static bool s_enable_vmalloc = false;

void memory_event_enable_vmalloc(bool enable) {
    s_enable_vmalloc = enable;
}

bool memory_event_is_enable_vmalloc() {
#ifdef MEMORY_IGNORE_VMALLOCATE
    return false;
#endif
    
    return s_enable_vmalloc;
}

///
///-------------------------------------------------------------------------------------------------------
///

static const int s_charcodetable_basecode_int = 7; // must be > 0
static const char s_charcodetable_basecode_char = 20; // must be > 0

namespace {

class CharDecodeTable {
public:
    CharDecodeTable() {
        int index = s_charcodetable_basecode_int;
        for (char c = 'z'; c >= 'a'; c--) {
            _intcharmap[index] = c - s_charcodetable_basecode_char;
            ++index;
        }
        _intcharmap[index] = '_' - s_charcodetable_basecode_char;
        ++index;
        for (char c = 'A'; c <= 'Z'; c++) {
            _intcharmap[index] = c - s_charcodetable_basecode_char;
            ++index;
        }
    }
    
    void getString(int *szCode, std::string & str) {
        str.clear();
        for (int index = 0; index < 200; index++) {
            int value = szCode[index];
            if (value == 0) {
                break;
            }
            char c = _intcharmap[value] + s_charcodetable_basecode_char;
            str.push_back(c);
        }
    }
private:
    std::unordered_map<int, char> _intcharmap;
};

}


void memory_event_get_name_one(std::string & name) {
    // sz___syscall_logger
//    int sz[] = { 33, 33, 14, 8, 14, 30, 32, 21, 21, 33, 21, 18, 26, 26, 28, 15, 0 };
//    auto decode = CharDecodeTable();
//    decode.getString(sz, name);
    
    name = std::string("__syscall_logger");
}

void memory_event_get_name_two(std::string & name) {
    // sz___CFObjectAllocSetLastAllocEventNameFunction
//    int sz[] = { 33, 33, 36, 39, 48, 31, 23, 28, 30, 13, 34, 21, 21, 18, 30, 52, 28, 13, 45, 32, 14, 13, 34, 21, 21, 18, 30, 38, 11, 28, 19, 13, 47, 32, 20, 28, 39, 12, 19, 30, 13, 24, 18, 19, 0 };
//    auto decode = CharDecodeTable();
//    decode.getString(sz, name);
    
    name = std::string("__CFObjectAllocSetLastAllocEventNameFunction");
}

void memory_event_get_name_three(std::string & name) {
    // sz___CFOASafe
//    int sz[] = { 33, 33, 36, 39, 48, 34, 52, 32, 27, 28, 0 };
//    auto decode = CharDecodeTable();
//    decode.getString(sz, name);
    
    name = std::string("__CFOASafe");
}
