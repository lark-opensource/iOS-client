/*!@file HMDCrashGameScriptStack.c
 */

#include <stddef.h>
#include "HMDMacro.h"
#include "HMDCrashGameScriptStack.h"

static HMDCrashGameScriptCallback shared_callback = NULL;

void HMDCrashGameScriptStack_register(HMDCrashGameScriptCallback _Nullable callback) {
    __atomic_store_n(&shared_callback, callback, __ATOMIC_RELEASE);
}

HMDCrashGameScriptCallback _Nullable HMDCrashGameScriptStack_currentCallback(void) {
    return __atomic_load_n(&shared_callback, __ATOMIC_ACQUIRE);
}
