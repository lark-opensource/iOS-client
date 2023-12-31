//
//  HMDGetImages.cpp
//  Heimdallr
//
//  Created by APM on 2022/9/1.
//

#include "HMDGetImages.hpp"
#include <mach-o/loader.h>
#include <atomic>
#include <pthread.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>


#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
#endif

static std::vector<const mach_header *> images;
static std::atomic_bool no_need_to_add_image(false);
static pthread_mutex_t mutex_to_protect_array = PTHREAD_MUTEX_INITIALIZER;

static void addImage(const struct mach_header *header, intptr_t slide) {
    if(no_need_to_add_image) return;
    pthread_mutex_lock(&mutex_to_protect_array);
    images.emplace_back(header);
    pthread_mutex_unlock(&mutex_to_protect_array);
}

static void dfsDylib(std::string path, std::unordered_map<std::string, std::vector<std::string>> &map,
                     std::unordered_map<std::string, bool> &visited, std::set<std::string> &dylibSet){
    std::vector<std::string> vec = map[path];
    for(std::string p : vec){
        if(!visited.count(p)){
            dylibSet.insert(p);
            visited[p] = true;
            dfsDylib(p, map, visited, dylibSet);
        }
    }
}

static bool startsWith(const std::string& str, const std::string prefix) {
    return (str.find(prefix, 0) == 0);
}

static bool isUserDylib(const std::string& p){
    return !startsWith(p, "/usr/lib") && !startsWith(p, "/System") && !startsWith(p, "/Developer");
}

static void mapImageWithDylib(std::string eachImagePath, unsigned long index, const mach_header * eachImageHeader,
                              std::unordered_map<std::string, std::vector<std::string>> &map){
    if(isUserDylib(eachImagePath)){
        segment_command_t *cur_seg_cmd;
        uintptr_t cur = (uintptr_t) eachImageHeader + sizeof(mach_header_t);
        std::vector<std::string> vec;
        for (int i = 0; i < eachImageHeader->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
            cur_seg_cmd = (segment_command_t *) cur;
            if (cur_seg_cmd->cmd == LC_LOAD_DYLIB || cur_seg_cmd->cmd == LC_LOAD_WEAK_DYLIB) {
                const dylib_command* dylibCmd = (dylib_command*)cur_seg_cmd;
                const char* loadPath = (char*)dylibCmd + dylibCmd->dylib.name.offset;
                std::string p(loadPath);
                if(isUserDylib(p)){
                    unsigned long index = p.find_last_of('/');
                    if(index != p.npos){
                        vec.emplace_back(p.substr(index));
                    }
                }

            }
        }
        map[eachImagePath.substr(index)] = vec;
    }
}

std::vector<std::string> getPreloadDylibPath(){
    _dyld_register_func_for_add_image(addImage);
    no_need_to_add_image = true;
    pthread_mutex_lock(&mutex_to_protect_array);
    std::vector<const mach_header *> copiedImages(images);
    pthread_mutex_unlock(&mutex_to_protect_array);
    std::vector<std::string> appImages;
    std::string execImage;
    std::unordered_map<std::string, std::vector<std::string>> map;
    for(const mach_header * eachImageHeader : copiedImages){
        Dl_info info;
        if(dladdr(eachImageHeader, &info)){
            std::string eachImagePath(info.dli_fname);
            unsigned long index = eachImagePath.find_last_of('/');
            if(index != eachImagePath.npos){
                if(eachImageHeader->filetype == MH_EXECUTE){
                    execImage = eachImagePath.substr(index);
                }
                else if(isUserDylib(eachImagePath)){
                    appImages.emplace_back(eachImagePath);
                }
                mapImageWithDylib(eachImagePath, index, eachImageHeader, map);
            }
        }
    }
    std::unordered_map<std::string, bool> visited;
    std::set<std::string> dylibSet;
    dfsDylib(execImage, map, visited, dylibSet);
    std::vector<std::string> ret;
    for(std::string p : appImages){
        unsigned long index = p.find_last_of('/');
        if(index != p.npos && dylibSet.count(p.substr(index))){
            ret.emplace_back(p);
        }
    }
    return ret;
}
