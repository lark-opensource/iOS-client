//
//  HMDAsyncThreadState.c
//  AFgzipRequestSerializer
//
//  Created by yuanzhangjing on 2020/1/21.
//

#include "HMDAsyncThreadState.h"
#include "hmd_logger.h"
#include "HMDAsyncRegister.h"

void hmd_thread_state_mcontext_init(hmd_thread_state_t *thread_state, const hmd_thread_state_t *state) {
    if (thread_state && state) {
        *thread_state = *state;
    }
}

/**
 * Initialize the @a thread_state using thread state fetched from the given mach @a thread. If the thread is not
 * suspended, the fetched state may be inconsistent.
 *
 * All registers will be marked as available.
 *
 * @param thread_state The thread state to be initialized.
 * @param thread The thread from which to fetch thread state.
 *
 * @return Returns HMDFRAME_ESUCCESS on success, or standard hmdframe_error_t code if an error occurs.
 */
hmd_error_t hmd_thread_state_mach_thread_init(hmd_thread_state_t *thread_state, thread_t thread) {
    
    if (thread_state == NULL) {
        return HMD_EINVAL;
    }
    
    mach_msg_type_number_t state_count = HMD_THREAD_STATE_COUNT;
    thread_state_flavor_t flavor = HMD_THREAD_STATE;

    natural_t buffer[state_count];
    thread_state_t state = buffer;
    kern_return_t kr = thread_get_state(thread, flavor, state, &state_count);
    if (kr != KERN_SUCCESS) {
        HMDLOG_ERROR("Fetch of ARM thread state failed with Mach error: %d", kr);
        return HMD_EINTERNAL;
    }

    hmd_thread_state_t *ctx = (hmd_thread_state_t *)state;
    hmd_thread_state_mcontext_init(thread_state, ctx);

    return HMD_ESUCCESS;
}

hmd_greg_t hmd_thread_state_get_fp(const hmd_thread_state_t *thread_state) {
    return HMD_GET_FP(thread_state);
}

hmd_greg_t hmd_thread_state_get_sp(const hmd_thread_state_t *thread_state) {
    return HMD_GET_SP(thread_state);
}

hmd_greg_t hmd_thread_state_get_lr(const hmd_thread_state_t *thread_state) {
    return HMD_GET_LR(thread_state);
}

hmd_greg_t hmd_thread_state_get_pc(const hmd_thread_state_t *thread_state) {
    return HMD_GET_PC(thread_state);
}

void hmd_thread_state_set_fp(hmd_thread_state_t *thread_state, uintptr_t value) {
    HMD_SET_FP(thread_state, value);
}

void hmd_thread_state_set_sp(hmd_thread_state_t *thread_state, uintptr_t value) {
    HMD_SET_SP(thread_state, value);
}

void hmd_thread_state_set_lr(hmd_thread_state_t *thread_state, uintptr_t value) {
    HMD_SET_LR(thread_state, value);
}

void hmd_thread_state_set_pc(hmd_thread_state_t *thread_state, uintptr_t value) {
    HMD_SET_PC(thread_state, value);
}
