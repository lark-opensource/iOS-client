//
//  hmd_apple_backtrace_log.m
//  Pods
//
//  Created by 白昆仑 on 2020/2/4.
//

#import <string>
#import "hmd_apple_backtrace_log.h"
#import "hmd_symbolicator.h"
#import "HMDDeviceTool.h"
#import "HMDCompactUnwind.hpp"
#import "HMDMacro.h"

extern hmd_thread hmdbt_main_thread;

void hmd_get_demangle_name(hmd_dl_info *info) {
    char *mangleName = info->dli_sname;
    if(mangleName == NULL) return;
    
//#if !HMD_APPSTORE_REVIEW_FIXUP
    static char* (*swift_demangle)(const char *mangledName,
                                   size_t mangledNameLength,
                                   char *outputBuffer,
                                   size_t *outputBufferSize,
                                   uint32_t flags) = nullptr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swift_demangle = (char *(*)(const char *, size_t, char *, size_t *, uint32_t))dlsym(RTLD_DEFAULT, "swift_demangle");
    });
    if (swift_demangle != nullptr) {
        size_t demangledSize = 0;
        char *demangleName = swift_demangle(mangleName, strlen(mangleName), nullptr, &demangledSize, 0);
        if (demangleName != nullptr) {
            memset(info->dli_sname, 0, sizeof(info->dli_sname));
            strncpy(mangleName, demangleName, sizeof(info->dli_sname));
            mangleName[sizeof(info->dli_sname)-1] = 0;
            free(demangleName);
        }
    }
//#endif  /* !HMD_APPSTORE_REVIEW_FIXUP */
    return;
}

// -返回单个线程需要显示的额外信息 并转换成json格式
// -使用完后需要在返回函数及时释放
// -Thread 0 name: {"thread_name":"Obtained stacks of main thread when main thread was stuck after 8s","metrics":{"cpu_usage":90.1, "gpu":80.1},"tag":{"thread_id":"1234", "thread_idx":"10000"} }
char *_Nullable hmd_backtrace_json_log_of_thread(hmdbt_backtrace_t *backtrace) {
    if(backtrace == NULL) return NULL;
    size_t line_max_length = 1024 * 5;
    char *line_log = (char *)calloc(line_max_length, sizeof(char)); // 单行log buffer
    if(line_log == NULL) return NULL;
    const char* run_state = "";
    const char* flags = "";
    switch (backtrace->run_state) {
        case TH_STATE_RUNNING:
        {
            run_state = "running";
            break;
        }
        case TH_STATE_STOPPED:
        {
            run_state = "stopped";
            break;
        }
        case TH_STATE_WAITING:
        {
            run_state = "waiting";
            break;
        }
        case TH_STATE_UNINTERRUPTIBLE:
        {
            run_state = "uninterruptible";
            break;
        }
        case TH_STATE_HALTED:
        {
            run_state = "halted";
            break;
        }
        default:
            break;
    }

    switch (backtrace->flags) {
        case TH_FLAGS_SWAPPED:
        {
            flags = "swapped out";
            break;
        }
        case TH_FLAGS_IDLE:
        {
            flags = "idle";
            break;
        }
        case TH_FLAGS_GLOBAL_FORCED_IDLE:
        {
            flags = "global forced idle";
            break;
        }
        default:
            break;
    }
    snprintf(line_log, line_max_length,
             "{ \"%s\":\"%s\",\"%s\":{\"%s\":%.2f},\"%s\":{\"%s\":\"%u\",\"%s\":\"%zu\",\"%s\":\"%s\", \"%s\":\"%s\", \"%s\":\"%d\"} }",
             "thread_name", backtrace->name,
             "metrics",
             "thread_cpu_usage", backtrace->thread_cpu_usage,
             "tag",
             "thread_id", backtrace->thread_id,
             "thread_idx",backtrace->thread_idx,
             "run_state", run_state,
             "flags", flags,
             "priority", backtrace->pth_curpri
            );
    return line_log;
}

// -返回char*log日志 仅watchdog模块调用过
char * HMD_NO_OPT_ATTRIBUTE hmd_apple_backtraces_log_of_all_threads(thread_t keyThread, unsigned long maxThreadCount, unsigned long skippedDepth, bool suspend, HMDLogType type, char *exceptionField, char *reasonField, bool needSymbol) {
    int backtrace_size = 0;
    hmdbt_backtrace_t *backtraces = hmdbt_origin_backtraces_of_all_threads(&backtrace_size, skippedDepth+1, suspend, maxThreadCount);
    if (backtraces == NULL) {
        return NULL;
    }
    
    char *log = hmd_apple_backtraces_log_of_threads(backtraces, backtrace_size, keyThread, type, exceptionField, reasonField, needSymbol);
    hmdbt_dealloc_bactrace(&backtraces, backtrace_size);
    GCC_FORCE_NO_OPTIMIZATION return log;
}

// -仅watchdog的全线程抓栈调用过该函数
char *hmd_apple_backtraces_log_of_threads(hmdbt_backtrace_t *backtraces,
                                          int backtrace_size,
                                          thread_t keyThread,
                                          HMDLogType type,
                                          char *exceptionField,
                                          char *reasonField,
                                          bool needSymbolName) {
    if (backtraces == NULL || backtrace_size == 0) {
        return NULL;
    }
    
    hmd_setup_shared_image_list_if_need();
    
    __block std::string log = "";
    size_t line_max_length = 1024 * 5; // 单行log不超过5KB，超过部分会被截断
    __block char *line_log = (char *)calloc(line_max_length, sizeof(char)); // 单行log buffer
    if (line_log == NULL) {
        return NULL;
    }
    
    // header
    char *header = hmd_log_header(type);
    if (header == NULL) {
        return NULL;
    }
    
    log.append(header);
    log.append("\n");
    free(header);
    header = NULL;
    if (exceptionField != NULL) {
        snprintf(line_log, line_max_length, "exception %s\n", exceptionField);
        log.append(line_log);
    }
    
    if (reasonField != NULL) {
        snprintf(line_log, line_max_length, "reason %s\n", reasonField);
        log.append(line_log);
    }
    
    // stack
    struct hmd_dl_info info = {0};
    for (int i=0; i<backtrace_size; i++) {
        hmdbt_backtrace_t *backtrace = &(backtraces[i]);
        char *threadInfoJson = hmd_backtrace_json_log_of_thread(backtrace);
        if(threadInfoJson != NULL) {
            snprintf(line_log, line_max_length, "Thread %lu name: %s\n", backtrace->thread_idx, threadInfoJson);
            free(threadInfoJson);
            threadInfoJson = NULL;
        } else
            snprintf(line_log, line_max_length, "Thread %lu name: %s\n", backtrace->thread_idx, backtrace->name);
        log.append(line_log);
        
        snprintf(line_log, line_max_length, "Thread %lu%s:\n", backtrace->thread_idx, (backtrace->thread_id == keyThread) ? " Crashed" : "");
        log.append(line_log);
        
        for (int j=0; j<backtrace->frame_count; j++) {
            hmdbt_frame_t *frame = &(backtrace->frames[j]);
#ifdef DEBUG
            bool rst = hmd_symbolicate(CALL_INSTRUCTION_FROM_RETURN_ADDRESS(frame->address), &info, needSymbolName);
#else
            bool rst = hmd_symbolicate(CALL_INSTRUCTION_FROM_RETURN_ADDRESS(frame->address), &info, false);
#endif
            if (rst) {
                char *image_name = strrchr(info.dli_fname, '/');
                if (image_name != NULL) {
                    image_name++;
#ifdef DEBUG
                    // 获取demangleName
                    hmd_get_demangle_name(&info);
#endif
                }
                snprintf(line_log, line_max_length, "%-4lu%-31s 0x%016lx 0x%lx + %lu ((%s) + %lu)\n",
                        frame->stack_index,
                        (image_name != NULL) ? image_name : "NULL",
                        frame->address,
                        (unsigned long)info.dli_fbase,
                        frame->address - (unsigned long)info.dli_fbase,
                        (strlen(info.dli_sname) > 0) ? info.dli_sname : "null",
                        frame->address - (unsigned long)info.dli_saddr);
            }
            else {
                snprintf(line_log, line_max_length, "%-4lu%-31s 0x%lx 0x%x + %lu ((%s) + %lu)\n",
                        frame->stack_index,
                        "NULL",
                        frame->address,
                        0,
                        frame->address - 0,
                        "null",
                        frame->address - 0);
            }
            
            log.append(line_log);
        }
        
        log.append("\n\n");
    }
    
    // image
    log.append("\nBinary Images:\n");
    hmd_enumerate_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
        if (image != NULL) {
            bool isExcutable = hmd_async_macho_is_executable(&image->macho_image);
            int cpuType = hmd_async_macho_cpu_type(&(image->macho_image));
            int cpuSubType = hmd_async_macho_cpu_subtype(&(image->macho_image));
            char * _Nullable arch = hmd_cpu_arch(cpuType, cpuSubType, false);
            char *image_name = strrchr(image->macho_image.name, '/');
            if (image_name != NULL) {
                image_name++;
            }
            snprintf(line_log, line_max_length, "%#10lx - %#10lx %s%s %s <%s> %s\n",
                    (unsigned long)(image->macho_image.header_addr),
                    (unsigned long)(image->macho_image.header_addr + image->macho_image.text_segment.size -1),
                    isExcutable ? "+" : " ",
                    (image_name != NULL) ? image_name : "null",
                    arch,
                    image->macho_image.uuid,
                    image->macho_image.name);
            log.append(line_log);
        }
    });
    
    free(line_log);
    line_log = NULL;
    return strdup(log.c_str());
}

char *hmd_apple_clear_backtrace_log_of_thread(hmdbt_backtrace_t *backtrace) {
    hmd_setup_shared_image_list_if_need();
    if (backtrace == NULL || backtrace->frames == NULL || backtrace->frame_count == 0) {
        return NULL;
    }
    
    std::string log = "";
    size_t line_max_length = 1024 * 5; // 单行log不超过5KB，超过部分会被截断
    char *line_log = (char *)calloc(line_max_length, sizeof(char)); // 单行log buffer
    if (line_log == NULL) {
        return NULL;
    }
    
    // -将线程名及线程相关信息转换成json字符串
    // -Thread 0 name: {"thread_name":"Obtained stacks of main thread when main thread was stuck after 8s","metrics":{"cpu":90.1, "gpu":80.1},"tag":{"thread_id":"1234", "thread_idx":"10000"} }
    
    char *threadInfoJson = hmd_backtrace_json_log_of_thread(backtrace);
    if(threadInfoJson != NULL) {
        snprintf(line_log, line_max_length, "Thread %lu name: %s\n", backtrace->thread_idx, threadInfoJson);
        free(threadInfoJson);
        threadInfoJson = NULL;
    } else
        snprintf(line_log, line_max_length, "Thread %lu name: %s\n", backtrace->thread_idx, backtrace->name);
    log.append(line_log);
    
    snprintf(line_log, line_max_length, "Thread %lu:\n", backtrace->thread_idx);
    log.append(line_log);
    
    struct hmd_dl_info info = {0};
    for (int j=0; j<backtrace->frame_count; j++) {
        hmdbt_frame_t *frame = &(backtrace->frames[j]);
        bool rst = hmd_symbolicate(CALL_INSTRUCTION_FROM_RETURN_ADDRESS(frame->address), &info, false);
        if (rst) {
            char *image_name = strrchr(info.dli_fname, '/');
            if (image_name != NULL) {
                image_name++;
            }
            snprintf(line_log, line_max_length, "%-4lu%-31s 0x%016lx 0x%lx + %lu ((%s) + %lu)\n",
                    frame->stack_index,
                    (image_name != NULL)?image_name:"NULL",
                    frame->address,
                    (unsigned long)info.dli_fbase,
                    frame->address - (unsigned long)info.dli_fbase,
                    (strlen(info.dli_sname) > 0) ? info.dli_sname : "null",
                    frame->address - (unsigned long)info.dli_saddr);
        }
        else {
            snprintf(line_log, line_max_length, "%-4lu%-31s 0x%lx 0x%x + %lu ((%s) + %lu)\n",
                    frame->stack_index,
                    "NULL",
                    frame->address,
                    0,
                    frame->address - 0,
                    "null",
                    frame->address - 0);
        }
        
        log.append(line_log);
    }
    
    log.append("\n\n");
    free(line_log);
    line_log = NULL;
    return strdup(log.c_str());
}
