//
//  HMDOtherSDKSignal.c
//  CaptainAllred
//
//  Created by somebody on somday
//

#include <dlfcn.h>
#include <signal.h>
#include <sys/errno.h>

#include "HMDMacro.h"
#include "HMDCrashSDKLog.h"
#include "HMDOtherSDKSignal.h"
#include "HMDOtherSDKSignal+Private.h"

typedef int (*sigaction_func_t)(int, const struct sigaction *, struct sigaction *);
static sigaction_func_t _Nullable fetch_sigaction_real(void);

int hmd_real_sigaction(int code,
                       const struct sigaction * __restrict _Nullable newAction,
                       struct sigaction * __restrict _Nullable oldAction) {
    
    sigaction_func_t _Nullable function = fetch_sigaction_real();
    
    if(unlikely(function == NULL)) {
        
        SDKLog_error("[sigaction][real] failed to find real function");
        
        GCC_FORCE_NO_OPTIMIZATION
        
        return -1;
    }
    
    int result = function(code, newAction, oldAction);
    
    GCC_FORCE_NO_OPTIMIZATION
    
    return result;
    
    return 0;
}

static sigaction_func_t _Nullable fetch_sigaction_real(void) {
    static sigaction_func_t real_function = NULL;
    
    sigaction_func_t _Nullable current_function = __atomic_load_n(&real_function, __ATOMIC_ACQUIRE);
    if(current_function != NULL) return current_function;
    
    current_function = dlsym(RTLD_NEXT, "sigaction");
    
    if(current_function != NULL) {
        
        __atomic_store_n(&real_function, current_function, __ATOMIC_RELEASE);
        
    } DEBUG_ELSE
    
    return current_function;
}

#pragma mark - break point

#ifdef DEBUG
static bool enable_breakpoint = false;  // 总之会被链接优化掉
#endif

void hmd_enable_other_SDK_signal_register_breakpoint(void) {
#ifdef DEBUG
    enable_breakpoint = true;
#endif
}

static void hmd_other_SDK_breakpoint(void) {
#ifdef DEBUG
    if(enable_breakpoint) {
        DEVELOP_DEBUG_POINT;
    }
#endif
}

#pragma mark - Hook

int sigaction(int code,
              const struct sigaction * __restrict _Nullable newAction,
              struct sigaction * __restrict _Nullable oldAction) {
    
    uint32_t sa_mask = UINT32_C(0x0);
    int sa_flags = 0;
    void * _Nullable handler = NULL;
    
    if(newAction != NULL) {
        DEBUG_ASSERT(sizeof(uint32_t) == sizeof(newAction->sa_mask));
        sa_mask = newAction->sa_mask;
        handler = newAction->sa_handler;
    }
    
    SDKLog_warn("[sigaction][rejected] code:%d mask:%u flag:%d handle:%p", 
                (unsigned int)sa_mask, sa_flags, handler);
    
    hmd_other_SDK_breakpoint();
    
    errno = EINVAL;
    
    return -1;
}

typedef void (*sig_func_t)(int);

sig_func_t signal(int code, sig_func_t newAction) {
    
    SDKLog_warn("[signal][rejected] code:%d handle:%p", code, (void *)newAction);
    
    hmd_other_SDK_breakpoint();
    
    errno = EINVAL;
    
    return SIG_ERR;
}

#pragma mark - Live Keeper

bool hmd_other_SDK_signal_live_keeper(void) {
    return true;
}
