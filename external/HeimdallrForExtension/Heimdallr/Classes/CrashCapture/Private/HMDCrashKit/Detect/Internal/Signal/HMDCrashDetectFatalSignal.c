//
//  HMDCrashDetectFatalSignal.c
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/14.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include <stdlib.h>
#include <signal.h>
#include <stdatomic.h>
#include <errno.h>
#include "HMDCrashDetectFatalSignal.h"
#include "HMDCrashSDKLog.h"
#include "hmd_signal_info.h"
#include "hmd_machine_context.h"
#include "hmd_stack_cursor_machine_context.h"
#include "HMDCrashDetectShared.h"
#include "HMDTimeSepc.h"
#include "HMDCrashException.h"
#include "HMDCrashOnceCatch.h"
#define SDK_LOG_MESSAGE_SIZE 128
#define SIGNAL_REASON_SIZE 256

static stack_t signal_stack = {0};
static struct sigaction * origninal_handle = NULL;

static void handle_signal(int signum, siginfo_t *signal_info, void *user_context);
static bool is_signal_handler_safe(int signum);

void HMDCrashDetect_signal_start(void) {
    
    {   /*  signalstask 是一份冗余代码, 如果可以考虑从将来发行的版本去除, 该部分代码意义不大
            (该部分代码已使用大括号标记出范围, 覆盖与 signal_stack 相关的代码)
         
            我们首先理解 signalstack 函数的作用, 之后我们也能够进一步理解作者使用 signalstack
            的意图, 以及为什么他犯了这个错误 (虽然不会造成坏处, 但是无效的内存增加也是不合理之处)
         
        [简明定义]
            signalstack 是提供[栈], 准确来说是 signal 信号发生的时刻额外使用的[栈]
         
        [栈是什么]
            heap[堆] 和 stack[栈] 是程序运行的两大动态内存分配地方; 使用 malloc 分配的的内存
            是放置在 heap[堆] 上的; 平时使用 int a; 这样的声明方式, 分配内存占据的空间在
            stack[栈] 上; 每一个线程都会有一个独立的栈空间; 栈的分配是往低地址分配的; 寄存器中的
            sp 寄存器就是目前栈分配位置 (说这么多其实就是想让回想起栈是什么 = =)
         
         [信号发生]
            如果一个信号发生, 带来的是线程强制转跳执行信号处理函数代码, 再完成执行代码后再继续运行;
            那么信号处理函数也会需要某些栈空间; 从常理来说, 就会如果信号确定要在当前线程进行处理,
            那么就会使用当前线程剩余的栈空间进行处理(信号处理在哪一个线程发生在后续会提到); 你可能
            会说, 那不是有栈空间用么, 为什么要提供额外的 stack[栈] 空间作为信号处理函数使用的栈
            内存呢？这不是本末导致么 (请听下文分解)
         
         [为信号处理准备额外的栈]
            客官别急, 请听如下的场景, 假设我们写了一个函数, 不小心无限的递归咯; 那么在实际中的栈就会
            表现为如下:
                            my_recursive_function()  <= 我们无限递归的函数
                            ...
                            my_recursive_function()
                            my_recursive_function()
                            my_recursive_function()
                            main()
                            dyld()
         
            它会无限递归下去, 一直到把栈空间给完全占用完. 要注意操作系统是没有办法分辨, 一个函数的递归
            到底是合理的还是不合理的, 它只会不停的执行, 一直到使用完整个栈空间. 最后需要调用新的函数的
            时刻, 已经没有更多的栈内存, 那么就会访问到非法的内存空间, 从而触发信号 SIGSEGV
         
                SIGSEGV = signal segment violation (invalid memory reference)
         
            那么如果在发生 SIGSEGV 场景的条件下, 信号被操作系统发送到发生异常的该线程上, 但是该线程
            已经没有更多的 stack[栈] 空间让信号处理函数进行处理, 这样的程序就会直接被系统中止, 也就
            不会再有用户可以操作的记录崩溃信息再 gracefully 优雅的退出应用
         
        [signalstack 的使用]
            signalstack 可以指明额外的栈空间, 让信号发生的时刻, 信号处理函数有单独的栈空间; 注意该
            函数需要配合 SA_ONSTACK 选项同步使用
         
        [信号会在哪个线程上处理]
            POSIX 给出的标准是[未定义], 也就是可能是任意的属于该程序的线程; 但是实际上很有规律, 如果是
            当前线程引发的信号, 那么就在当前线程处理 (例如 raise(SIGABRT); SIGSEGV); 如果是来自操作
            系统或者其他应用发送给你的信号, 那么就会在主线程进行处理
            (题外话: 假设有 SIGINT 信号, 如果在子线程使用 raise 引发, 那么就会在子线程进行信号处理;
             如果是使用 kill 引发, 反而是在主线程进行处理; 想想为什么哈, 不难的)
         
        [为什么这里使用 signalstack 意义不大]
            首先我们要明确根据 POSIX.1-2017 标准, signalstack 只能够指定 [当前线程] 的信号函数栈;
            而当前线程是什么呢? Heimdallr 中 crash 模块是 sync 同步启动模块, 那么意味着取决于业务
            调用 -[Heimdallr setupWithInjectedInfo:] 的线程; 如果该线程是主线程, 那么有一定的
            存在意义, 至少在主线程栈溢出的时刻引发异常可以额外处理; 如果该线程是昙花一现的某个子线程,
            那么将毫无意义; 然后现在 D、N 在搞启动优化, Heimdallr 能否主线程同步启动岌岌可危
         
         [可以存在 signalstack 覆盖所有线程吗]
            我们首先要明确 signal 是可能同时发生的, 也可能同时发生在不同线程, 那么也不可能存在不同线程
            共享栈的实现; 所以从理论上来说是无法实现的
         
         [如何进行改进呢]
            方案1: 删掉 signalstack, 它存在的本身意义不大, 因为如果栈溢出是首先 EXC_BAD_ACCESS
            方案2: dispatch 到主线程, 首先判断是否之前存在 signalstack, 否则注册 signalstack */
        
        if(signal_stack.ss_size == 0) {
            signal_stack.ss_size = SIGSTKSZ;
            signal_stack.ss_sp = malloc(signal_stack.ss_size);
        }
        
        if (sigaltstack(&signal_stack, NULL) != 0) {
            int current_errno = errno;
            SDKLog_error("failed to set signal stack with errno %d", current_errno);
            return;
        }
    }
    
    int fatalNums = hmdsignal_numFatalSignals();
    const int *fatalSignals = hmdsignal_fatalSignals();
    
    if (origninal_handle == NULL) {
        origninal_handle = malloc(sizeof(struct sigaction) * fatalNums);
        if(origninal_handle == NULL) {
            SDKLog_error("allocate orignal signal handle storage failed");
            return;
        }
    }
    
    struct sigaction action = {{0}};
    action.sa_flags = SA_SIGINFO | SA_ONSTACK;
#if HMDCRASH_HOST_APPLE && defined(__LP64__)
    action.sa_flags |= SA_64REGSET;
#endif
    sigfillset(&action.sa_mask);
    action.sa_sigaction = &handle_signal;
    
    for(int index = 0; index < fatalNums; index++) {
        if(sigaction(fatalSignals[index], &action, &origninal_handle[index]) != 0) {
            /* Error happens */
            int current_errno = errno;
            SDKLog_error("failed to set signal %d with errno %d", fatalSignals[index], current_errno);
            
            for(index--; index >= 0; index--) {
                sigaction(hmdsignal_fatalSignals()[index], &origninal_handle[index], NULL);
            }
            return;
        }
    }
    SDKLog("signal detector launch complete");
}

void HMDCrashDetect_signal_end(void) {
    
    if (origninal_handle == NULL) {
        return;
    }
    
    int fatalNums = hmdsignal_numFatalSignals();
    const int *fatalSignals = hmdsignal_fatalSignals();
    
    for(int index = 0; index < fatalNums; index++)
        sigaction(fatalSignals[index], &origninal_handle[index], NULL);
    signal_stack = (stack_t){0};
    
    /* mach stop code end */
    SDKLog("signal detector shutdown complete");
}

static void record_signal(int signum, siginfo_t* signal_info, void* user_context, struct hmd_crash_env_context *envContextPointer)
{
    hmdcrash_detector_context_t context;
    memset(&context, 0, sizeof(context));
    context.crash_time = HMD_XNUSystemCall_timeSince1970();
    context.crash_type = HMDCrashTypeFatalSignal;
    if (signal_info) {
        context.fault_address = (uintptr_t)signal_info->si_addr;
        context.signal.signum = signal_info->si_signo;
        context.signal.sigcode = signal_info->si_code;
    }
    context.signal.user_context = user_context;
    
    SDKLog("writing basic info");
    basic_info(&context);
    
    //crash thread
    KSMC_NEW_CONTEXT(machineContext);
    machineContext->working_thread = envContextPointer->current_thread;
    hmdmc_get_state_with_signal(user_context, machineContext);
    hmd_stack_cursor cursor;
    hmdsc_initWithMachineContext(&cursor, machineContext);
    machineContext->cursor = &cursor;
    machineContext->fault_addr = context.fault_address;

    envContextPointer->crash_machine_ctx = machineContext;
    SDKLog("calling crash handler");
    hmd_crash_handler(envContextPointer, &context);
    
    SDKLog("crash handle finish");
}

static void handle_signal(int signum, siginfo_t *signal_info, void *user_context) {
    uintptr_t address = 0; int num = signum; int code = 0;
    if (signal_info != NULL) {
        address = (uintptr_t)signal_info->si_addr;
        num  = signal_info->si_signo;
        code = signal_info->si_code;
    }

    SDKLog("signal handler invoked, signum:%d(%s) sigcode:%d(%s) address:%p",num,hmdsignal_signalName(num),code,hmdsignal_signalCodeName(num, code),address);
    
    if (once_catch()) {
        KSMC_NEW_ENV_CONTEXT(envContextPointer);
        envContextPointer->current_thread = mach_thread_self();
        hmdmc_suspendEnvironment(envContextPointer);
        SDKLog("handling signal");
        if(!open_exception()) {
            SDKLog_error("signal handler open exception failed");
        }
        record_signal(signum, signal_info, user_context, envContextPointer);
    } else {
        wait_catch();
        write_extra_crash_info();
    }
    
    if(is_signal_handler_safe(signum)) {
        SDKLog("signal handler is safe, invoke");
    } else {
        SDKLog("signal handler is not safe, may cause death loop. exit");
        exit(EXIT_FAILURE);
    }
    raise(signum);
}

static bool is_signal_handler_safe(int signum) {
    struct sigaction cur_action; int ret;
    if ((ret = sigaction(signum, NULL, &cur_action)) != 0) {
        int current_errno = errno;
        SDKLog_error("failed to restore signal handler for signum:%d err:%d(%s)", signum, current_errno, strerror(current_errno));
    }
    else {
        if (cur_action.__sigaction_u.__sa_sigaction == handle_signal) return false;
        return true;    // clear signal handle success
    }
    return false;
}

bool HMDCrashDetect_signal_check(void)
{
    struct sigaction action;
    for(int i = 0; i < hmdsignal_numFatalSignals(); i++)
    {
        int ret = sigaction(hmdsignal_fatalSignals()[i], NULL, &action);
        if (ret == 0) {
            if (action.__sigaction_u.__sa_sigaction != handle_signal) {
                SDKLog_error("signal handler is invalid");
                return false;
            }
        } else {
            SDKLog_error("sigaction ret error %d",ret);
        }
    }
    
    SDKLog("signal handler is valid");

    return true;
}

