//
//  hmd_crash_safe_tool.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/7/2.
//

#ifndef hmd_crash_safe_tool_h
#define hmd_crash_safe_tool_h
#include <stdbool.h>

extern char hmd_executable_path[];
extern char hmd_main_bundle_path[];
extern char hmd_home_path[];

#ifdef __cplusplus
extern "C" {
#endif

    char *hmd_reliable_basename(const char *str);

    char *hmd_reliable_dirname(const char *str);
    
    int hmd_reliable_backtrace(void** buffer,int length);

    int hmd_reliable_fast_backtrace(void** buffer,int length);
        
    bool hmd_reliable_has_prefix(const char *str, const char *prefix);

    bool hmd_reliable_has_suffix(const char *str, const char *suffix);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* hmd_crash_safe_tool_h */
