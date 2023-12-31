//
//  hmd_machine_context.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_machine_context.h"
#include "hmd_stack_cursor_machine_context.h"
#include <mach/mach.h>
#include "HMDAsyncRegister.h"

#define HMDLogger_Level INFO
#include "hmd_logger.h"

#ifdef __arm64__
#define UC_MCONTEXT uc_mcontext64
typedef ucontext64_t SignalUserContext;
#else
#define UC_MCONTEXT uc_mcontext
typedef ucontext_t SignalUserContext;
#endif

int hmdmc_contextSize() {
    return sizeof(hmd_machine_context);
}

bool hmdmc_get_state_with_thread(hmd_thread thread, hmd_machine_context* destinationContext, bool isCrashedContext) {
    destinationContext->thread = (thread_t)thread;
    destinationContext->isCurrentThread = (thread == destinationContext->working_thread);
    destinationContext->isCrashedContext = isCrashedContext;
    destinationContext->isSignalContext = false;
    memset(&destinationContext->state, 0, sizeof(destinationContext->state));
    if (hmdmc_has_state(destinationContext)) {
        hmdmc_get_state(destinationContext);
    }
    return true;
}

bool hmdmc_get_state_with_signal(void* signalUserContext, hmd_machine_context* destinationContext) {
    _STRUCT_MCONTEXT* sourceContext = ((SignalUserContext*)signalUserContext)->UC_MCONTEXT;
    memcpy(&destinationContext->state, sourceContext, sizeof(destinationContext->state));
    destinationContext->thread = destinationContext->working_thread;
    destinationContext->isCrashedContext = true;
    destinationContext->isSignalContext = true;
    HMDLOG_TRACE("Context retrieved.");
    return true;
}

void hmdmc_suspendEnvironment(hmd_crash_env_context *ctx) {
    HMDLOG_INFO("Suspending environment.");
    kern_return_t kr;
    const task_t thisTask = mach_task_self();
    const thread_t thisThread = ctx->current_thread;

    if ((kr = task_threads(thisTask, &ctx->thread_list, &ctx->thread_count)) != KERN_SUCCESS) {
        HMDLOG_ERROR("task_threads: %d", kr);
        return;
    }

    for (mach_msg_type_number_t i = 0; i < ctx->thread_count; i++) {
        thread_t thread = ctx->thread_list[i];
        if (thread != thisThread && !hmdmac_thread_is_reserved(thread)) {
            if ((kr = thread_suspend(thread)) != KERN_SUCCESS) {
                // Record the error and keep going.
                HMDLOG_ERROR("thread_suspend (%d): %d", thread, kr);
            }
        }
    }

    HMDLOG_INFO("Suspend complete.");
}

void hmdmc_resumeEnvironment(hmd_crash_env_context *ctx) {
    HMDLOG_INFO("Resuming environment.");
    kern_return_t kr;
    const task_t thisTask = mach_task_self();
    const thread_t thisThread = ctx->current_thread;

    for (mach_msg_type_number_t i = 0; i < ctx->thread_count; i++) {
        thread_t thread = ctx->thread_list[i];
        if (thread != thisThread && !hmdmac_thread_is_reserved(thread)) {
            if ((kr = thread_resume(thread)) != KERN_SUCCESS) {
                // Record the error and keep going.
                HMDLOG_ERROR("thread_resume (%d): %d", thread, kr);
            }
        }
    }
    //判断是否发生了Crash，如果出现了Crash，则不释放，因为deallocate里面带有锁，防止出现死锁
    if (ctx->need_free_thread_list) {
        for (mach_msg_type_number_t i = 0; i < ctx->thread_count; i++) {
            mach_port_deallocate(thisTask, ctx->thread_list[i]);
        }
        vm_deallocate(thisTask, (vm_address_t)ctx->thread_list, sizeof(thread_t) * ctx->thread_count);
    }
    ctx->thread_count = 0;
    ctx->thread_list = NULL;
    HMDLOG_INFO("Resume complete.");
}

bool hmdmc_isCrashedContext(const hmd_machine_context* const context) {
    return context->isCrashedContext;
}

static inline bool isContextForCurrentThread(const hmd_machine_context* const context) {
    return context->isCurrentThread;
}

static inline bool isSignalContext(const hmd_machine_context* const context) {
    return context->isSignalContext;
}

bool hmdmc_has_state(const hmd_machine_context* const context) {
    return !isContextForCurrentThread(context) || isSignalContext(context);
}

static bool hmdmc_fill_state(const thread_t thread,
                             const thread_state_t state,
                             const thread_state_flavor_t flavor,
                             const mach_msg_type_number_t stateCount) {
    mach_msg_type_number_t stateCountBuff = stateCount;
    kern_return_t kr;
    kr = thread_get_state(thread, flavor, state, &stateCountBuff);
    if (kr != KERN_SUCCESS) {
        HMDLOG_ERROR("thread_get_state: %s", mach_error_string(kr));
        return false;
    }
    return true;
}

void hmdmc_get_state(struct hmd_machine_context* context) {
    thread_t thread = context->thread;
    hmd_thread_state_t* const state = &context->state;
    hmdmc_fill_state(thread, (thread_state_t)&state->__ss, HMD_THREAD_STATE, HMD_THREAD_STATE_COUNT);
    hmdmc_fill_state(thread, (thread_state_t)&state->__es, HMD_EXCEPTION_STATE, HMD_EXCEPTION_STATE_COUNT);
}

static thread_t reserved_threads[10];
static int reserved_thread_index = 0;

void hmdmc_add_reserved_thread(thread_t thread)
{
    if (sizeof(reserved_threads)/sizeof(thread_t) > reserved_thread_index) {
        reserved_threads[reserved_thread_index] = thread;
        reserved_thread_index++;
    }
}

bool hmdmac_thread_is_reserved(thread_t thread)
{
    for (int i = 0; i < reserved_thread_index; i++) {
        if (reserved_threads[i] == thread) {
            return true;
        }
    }
    return false;
}

#pragma mark - regular register

uintptr_t hmdmc_get_fp(const struct hmd_machine_context* const context) {
    return hmd_thread_state_get_fp(&context->state);
}

uintptr_t hmdmc_get_pc(const struct hmd_machine_context* const context) {
    return hmd_thread_state_get_pc(&context->state);
}

uintptr_t hmdmc_get_sp(const struct hmd_machine_context* const context) {
    return hmd_thread_state_get_sp(&context->state);
}

uintptr_t hmdmc_get_lr(const struct hmd_machine_context* const context) {
    return hmd_thread_state_get_lr(&context->state);
}

uintptr_t hmdmc_get_fault_address(const struct hmd_machine_context* const context) {
    return HMD_GET_FAR(&context->state);
}

#pragma mark - current thread

typedef struct hmdmc_frame {
    struct hmdmc_frame* previous;
    uintptr_t return_address;
} hmdmc_frame;

static bool hmdmc_unwind_with_fp(uintptr_t fp, hmdmc_frame *frame) {
    if (frame) {
        memset(frame, 0, sizeof(*frame));
        if (hmd_async_read_memory(fp, frame, sizeof(*frame)) == HMD_ESUCCESS) {
            return true;
        }
    }
    return false;
}

bool hmdmc_get_current_thread_state(hmd_thread_state_t* state) {
    if (state == NULL) {
        return false;
    }
    uintptr_t fp = (uintptr_t)__builtin_frame_address(0);
    
    hmdmc_frame frame = {0};
    if (hmdmc_unwind_with_fp(fp, &frame)) {
        hmd_thread_state_set_pc(state, frame.return_address);
        hmd_thread_state_set_fp(state, (uintptr_t)frame.previous);
        hmd_thread_state_set_sp(state, (fp + sizeof(void *) * 2));
        asm("");
        return true;
    }
    asm("");
    return false;
}

int hmdmc_num_registers(void) {
    return hmd_num_registers();
}

const char* hmdmc_register_name(const int regNumber) {
    return hmd_register_name(regNumber);
}

int hmdmc_num_exception_registers(void) {
    return hmd_num_exception_registers();
}

const char* hmdmc_exception_register_name(const int regNumber) {
    return hmd_exception_register_name(regNumber);
}

uintptr_t hmdmc_register_value(const hmd_machine_context* const context, const int regNumber) {
    return hmd_register_value(&context->state, regNumber);
}

uintptr_t hmdmc_exception_register_value(const hmd_machine_context* const context, const int regNumber) {
    return hmd_exception_register_value(&context->state, regNumber);
}
