//
//  hmd_machine_context.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#ifndef HDR_hmd_machine_context_h
#define HDR_hmd_machine_context_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include "HMDAsyncThread.h"
#include <mach/mach_types.h>
#include <sys/ucontext.h>
#include "hmd_types.h"

    struct hmd_stack_cursor;
    typedef struct hmd_machine_context {
        thread_t thread; //context代表的线程
        thread_t working_thread; //当前的工作线程
        bool isCrashedContext;
        bool isCurrentThread;
        bool isSignalContext;
        hmd_thread_state_t state;
        struct hmd_stack_cursor *cursor;
        uintptr_t fault_addr;
    } hmd_machine_context;
    
    typedef struct hmd_crash_env_context {
        hmd_machine_context *crash_machine_ctx;
        thread_t current_thread;
        thread_act_array_t thread_list;
        mach_msg_type_number_t thread_count;
        bool need_free_thread_list;
    } hmd_crash_env_context;
    
#define KSMC_NEW_ENV_CONTEXT(NAME) \
hmd_crash_env_context hmd_crash_##NAME##_on_stack = {}; \
hmd_crash_env_context *NAME = &hmd_crash_##NAME##_on_stack; \
memset(envContextPointer, 0, sizeof(hmd_crash_##NAME##_on_stack));

#define KSMC_NEW_CONTEXT(NAME)                        \
    char hmdmc_##NAME##_storage[hmdmc_contextSize()]; \
    struct hmd_machine_context* NAME = (struct hmd_machine_context*)hmdmc_##NAME##_storage ;\
    memset(NAME, 0, sizeof(hmdmc_##NAME##_storage));

void hmdmc_suspendEnvironment(struct hmd_crash_env_context *ctx);

void hmdmc_resumeEnvironment(struct hmd_crash_env_context *ctx);

int hmdmc_contextSize(void);

bool hmdmc_get_state_with_thread(hmd_thread thread,
                               hmd_machine_context* destinationContext,
                               bool isCrashedContext);

bool hmdmc_get_state_with_signal(void* signalUserContext,
                               hmd_machine_context* destinationContext);

bool hmdmc_has_state(const struct hmd_machine_context* const context);

void hmdmc_get_state(struct hmd_machine_context* context);

//not thread safe
void hmdmc_add_reserved_thread(thread_t thread);
//not thread safe
bool hmdmac_thread_is_reserved(thread_t thread);

uintptr_t hmdmc_get_fp(const struct hmd_machine_context* const context);

uintptr_t hmdmc_get_pc(const struct hmd_machine_context* const context);

uintptr_t hmdmc_get_sp(const struct hmd_machine_context* const context);

uintptr_t hmdmc_get_lr(const struct hmd_machine_context* const context);

uintptr_t hmdmc_get_fault_address(const struct hmd_machine_context* const context);

bool hmdmc_get_current_thread_state(hmd_thread_state_t* mcontext);

int hmdmc_num_registers(void);

const char* hmdmc_register_name(const int regNumber);

int hmdmc_num_exception_registers(void);

const char* hmdmc_exception_register_name(const int regNumber);

uintptr_t hmdmc_register_value(const hmd_machine_context* const context, const int regNumber);

uintptr_t hmdmc_exception_register_value(const hmd_machine_context* const context, const int regNumber);

#ifdef __cplusplus
}
#endif

#endif  // HDR_hmd_machine_context_h
