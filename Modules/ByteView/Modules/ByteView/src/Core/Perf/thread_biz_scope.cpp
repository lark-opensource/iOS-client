//
//  thread_biz_scope.cpp
//  ByteView
//
//  Created by liujianlong on 2023/4/4.
//

#include "thread_biz_scope.h"
#include <BDFishhook/BDFishhook.h>
#include <pthread/pthread.h>
#include <string>
#include <thread>
#include <mutex>
#include <dispatch/dispatch.h>
#include <map>
#include <mach-o/dyld.h>

namespace byteview {

class ThreadBizContext {
private:
    ThreadBizContext() {
        pthread_key_create(&pk_, nullptr);
    }

public:
    static ThreadBizContext* shared() {
        static std::once_flag once;
        static ThreadBizContext* inst;
        std::call_once(once, [&]() {
            inst = new ThreadBizContext();
        });
        return inst;
    }

    void clean_thread(uint64_t tid) {
        std::lock_guard<std::mutex> lock(threads_mutex_);
        thread_to_scope_.erase(tid);
        thread_to_parent_.erase(tid);
    }

    ByteViewThreadBizScope set_thread_scope(uint64_t tid, ByteViewThreadBizScope scope) {
        std::lock_guard<std::mutex> lock(threads_mutex_);
        auto old_scope = thread_to_scope_[tid];
        thread_to_scope_[tid] = scope;
        return old_scope;
    }

    ByteViewThreadBizScope get_thread_scope(uint64_t tid) {
        std::lock_guard<std::mutex> lock(threads_mutex_);
        return thread_to_scope_[tid];
    }

    ByteViewThreadBizScope get_current_biz_scope() {
        return (ByteViewThreadBizScope)(int64_t)pthread_getspecific(pk_);
    }

    ByteViewThreadBizScope set_current_biz_scope(ByteViewThreadBizScope scope) {
        uint64_t tid = 0;
        pthread_threadid_np(pthread_self(), &tid);
        auto oldValue = (ByteViewThreadBizScope)(int64_t)pthread_getspecific(pk_);
        set_thread_scope(tid, scope);
        pthread_setspecific(pk_, (void *)(int64_t)scope);
        return oldValue;
    }


    uint64_t get_thread_parent(uint64_t tid) {
        std::lock_guard<std::mutex> lock(threads_mutex_);
        return thread_to_parent_[tid];
    }

    void set_thread_parent(uint64_t tid, uint64_t parent) {
        std::lock_guard<std::mutex> lock(threads_mutex_);
        thread_to_parent_[tid] = parent;
    }


    void set_queue_scope(dispatch_queue_t queue, ByteViewThreadBizScope scope) {
        dispatch_queue_set_specific(queue, &queue_biz_key_, (void*)(int64_t)scope, NULL);
    }

    ByteViewThreadBizScope get_queue_scope() {
        auto biz_scope = dispatch_get_specific(&queue_biz_key_);
        if (biz_scope == NULL) {
            return ByteViewThreadBizScope_Unknown;
        }
        return (ByteViewThreadBizScope)(int64_t)biz_scope;
    }

    ByteViewThreadBizScope get_queue_scope(dispatch_queue_t queue) {
        auto biz_scope = dispatch_queue_get_specific(queue, &queue_biz_key_);
        if (biz_scope == NULL) {
            return ByteViewThreadBizScope_Unknown;
        }
        return (ByteViewThreadBizScope)(int64_t)biz_scope;
    }


private:
    std::map<uint64_t, ByteViewThreadBizScope> thread_to_scope_;
    std::map<uint64_t, uint64_t> thread_to_parent_;
    std::mutex threads_mutex_;
    pthread_key_t pk_;
    const char queue_biz_key_ = 0;
};

}

namespace {

//hmd_dladdr
static uintptr_t firstCmdAfterHeader(const struct mach_header* const header) {
    switch (header->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);
        default:
            // Header is corrupt
            return 0;
    }
}

static uint32_t imageIndexContainingAddress(const uintptr_t address) {
    const uint32_t imageCount = _dyld_image_count();
    const struct mach_header* header = 0;

    for (uint32_t iImg = 0; iImg < imageCount; iImg++) {
        header = _dyld_get_image_header(iImg);
        if (header != NULL) {
            // Look for a segment command with this address within its range.
            uintptr_t addressWSlide = address - (uintptr_t)_dyld_get_image_vmaddr_slide(iImg);
            uintptr_t cmdPtr = firstCmdAfterHeader(header);
            if (cmdPtr == 0) {
                continue;
            }
            for (uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
                const struct load_command* loadCmd = (struct load_command*)cmdPtr;
                if (loadCmd->cmd == LC_SEGMENT) {
                const struct segment_command* segCmd = (struct segment_command*)cmdPtr;
                    if (addressWSlide >= segCmd->vmaddr && addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;
                    }
                } else if (loadCmd->cmd == LC_SEGMENT_64) {
                    const struct segment_command_64* segCmd = (struct segment_command_64*)cmdPtr;
                    if (addressWSlide >= segCmd->vmaddr && addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;
                    }
                }
                cmdPtr += loadCmd->cmdsize;
            }
        }
    }
    return UINT32_MAX;
}

}


namespace byteview {

using byteview_thread_func = void *(* _Nonnull)(void *);

int (*origin_pthread_create)(pthread_t * __restrict,
                             const pthread_attr_t * _Nullable __restrict,
                             byteview_thread_func,
                             void * _Nullable __restrict);

struct ThreadLaunchParams {
    std::string thread_name;
    byteview_thread_func target_func;
    void *target_arg;
    ByteViewThreadBizScope biz_scope = ByteViewThreadBizScope_Unknown;
    uint64_t ptid = 0;
};

static void *hooked_thread_launch(ThreadLaunchParams *params) {
    pthread_setname_np(params->thread_name.c_str());
    auto target_func = params->target_func;
    auto target_args = params->target_arg;
    auto biz_scope = params->biz_scope;
    auto ptid = params->ptid;
    delete params;
    uint64_t tid = 0;
    pthread_threadid_np(pthread_self(), &tid);
    if (biz_scope != ByteViewThreadBizScope_Unknown) {
        byteview::ThreadBizContext::shared()->set_current_biz_scope(biz_scope);
    }
    byteview::ThreadBizContext::shared()->set_thread_parent(tid, ptid);
    auto ret = target_func(target_args);
    byteview::ThreadBizContext::shared()->clean_thread(tid);
    return ret;
}

static int hooked_pthread_create(pthread_t * __restrict p,
                                 const pthread_attr_t * _Nullable __restrict attr,
                                 void *(* _Nonnull fn)(void *), void * _Nullable __restrict arg) {
    auto cur_biz_scope = byteview::ThreadBizContext::shared()->get_current_biz_scope();
    if (cur_biz_scope == ByteViewThreadBizScope_Unknown) {
        return origin_pthread_create(p, attr, fn, arg);
    }
    auto hooked_arg = new ThreadLaunchParams();

    hooked_arg->thread_name.resize(128, 0);
    int rc = pthread_getname_np(pthread_self(),
                                &hooked_arg->thread_name[0],
                                hooked_arg->thread_name.size());
    hooked_arg->thread_name.resize(strlen(hooked_arg->thread_name.c_str()));
    if (rc == 0 && !hooked_arg->thread_name.empty()) {
        hooked_arg->thread_name.append("-child");
    }
    hooked_arg->target_func = fn;
    hooked_arg->target_arg = arg;
    hooked_arg->biz_scope = cur_biz_scope;

    auto child_pt = origin_pthread_create(p, attr, (byteview_thread_func)&hooked_thread_launch, (void *)hooked_arg);
    return child_pt;
}


static void (*origin_dispatch_async)(dispatch_queue_t queue, dispatch_block_t block);
static void hooked_dispatch_async(dispatch_queue_t queue, dispatch_block_t block) {
    auto bizScope = byteview_get_current_biz_scope();
    if (bizScope == ByteViewThreadBizScope_Unknown) {
        return origin_dispatch_async(queue, block);
    }
    origin_dispatch_async(queue, ^{
        auto oldScope = byteview::ThreadBizContext::shared()->set_current_biz_scope(bizScope);
        block();
        byteview::ThreadBizContext::shared()->set_current_biz_scope(oldScope);
    });
}

static void (*origin_dispatch_after)(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block);
static void hooked_dispatch_after(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block) {
    auto bizScope = byteview_get_current_biz_scope();
    if (bizScope == ByteViewThreadBizScope_Unknown) {
        return origin_dispatch_after(when, queue, block);
    }
    origin_dispatch_after(when, queue, ^{
        auto oldScope = byteview::ThreadBizContext::shared()->set_current_biz_scope(bizScope);
        block();
        byteview::ThreadBizContext::shared()->set_current_biz_scope(oldScope);
    });
}

}

void byteview_setup_thread_api(void) {
    static std::once_flag once;
    std::call_once(once, []() {
        using namespace byteview;
        auto img_idx = imageIndexContainingAddress((uintptr_t)(void *)&byteview_setup_thread_api);
        if (img_idx == UINT32_MAX) {
            return;
        }
        auto header = _dyld_get_image_header(img_idx);
        auto slide = _dyld_get_image_vmaddr_slide(img_idx);
        if (header == NULL || slide == 0) {
            return;
        }

#if DEBUG
        auto img_name = _dyld_get_image_name(img_idx);
        printf("[ByteView] hooked image name %s\n", img_name);
#endif
        struct bd_rebinding rebinds[] ={
            {
                "pthread_create",
                (void *)&hooked_pthread_create,
                (void **)&origin_pthread_create,
            },
            {
                "dispatch_async",
                (void *)&hooked_dispatch_async,
                (void **)&origin_dispatch_async,
            },
            {
                "dispatch_after",
                (void *)&hooked_dispatch_after,
                (void **)&origin_dispatch_after,
            },
        };
        bd_rebind_symbols_image((void *)header, slide, rebinds, sizeof(rebinds) / sizeof(bd_rebinding));
    });
}

ByteViewThreadBizScope byteview_get_current_biz_scope() {
    return byteview::ThreadBizContext::shared()->get_current_biz_scope();
}

ByteViewThreadBizScope byteview_set_current_biz_scope(ByteViewThreadBizScope scope) {
    return byteview::ThreadBizContext::shared()->set_current_biz_scope(scope);
}

ByteViewThreadBizScope byteview_get_thread_scope(uint64_t tid) {
    return byteview::ThreadBizContext::shared()->get_thread_scope(tid);
}

