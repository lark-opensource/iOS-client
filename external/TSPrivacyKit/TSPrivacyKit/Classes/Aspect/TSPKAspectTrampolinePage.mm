//
//  TSPKAspectTrampolinePage.m
//  iOS15PhotoDemo
//
//  Created by bytedance on 2021/11/23.
//

#import "TSPKAspectTrampolinePage.h"
#import "TSPKLogger.h"

#import <AssertMacros.h>
#import <libkern/OSAtomic.h>

#import <mach/vm_types.h>
#import <mach/vm_map.h>
#import <mach/mach_init.h>
#import <mach/arm/vm_param.h>
#import <os/lock.h>


extern char pns_forwarding_trampoline_page;
extern char pns_forwarding_trampoline_stret_page;

#if defined(__arm64__)

typedef int32_t PnSTrampolineEntryPointBlock[8];
#define M_PAGE_SIZE 0x4000
#define CODE_TRAMPOLINE_ENTRY_OFFSET 0x4180
static const int32_t PnSTrampolineInstructionCount = (CODE_TRAMPOLINE_ENTRY_OFFSET-M_PAGE_SIZE)/sizeof(int32_t);//92

#elif defined(_ARM_ARCH_7)

typedef int32_t PnSTrampolineEntryPointBlock[4];
#define M_PAGE_SIZE 0x1000
#define CODE_TRAMPOLINE_ENTRY_OFFSET 0x1110
static const int32_t PnSTrampolineInstructionCount = (CODE_TRAMPOLINE_ENTRY_OFFSET-M_PAGE_SIZE)/sizeof(int32_t);//16

#elif defined(__x86_64__)

typedef int32_t PnSTrampolineEntryPointBlock[4];
#define M_PAGE_SIZE 0x1000
#define CODE_TRAMPOLINE_ENTRY_OFFSET 0x14a0
static const int32_t PnSTrampolineInstructionCount = (CODE_TRAMPOLINE_ENTRY_OFFSET-M_PAGE_SIZE)/sizeof(int32_t);

#else
#error SPLMessageLogger is not supported on this platform
#endif

typedef struct {
    IMP oriImp;
    SEL oriCmd;
#if defined(__arm64__) || defined(_ARM_ARCH_7)
    IMP placeholder1;
    IMP placeholder2;
#endif
} PnSTrampolineDataBlock;//its size should be smaller or same than PnSTrampolineEntryPointBlock


static const size_t NumberOfTrampolinesEntryPerPage = (M_PAGE_SIZE - PnSTrampolineInstructionCount*sizeof(int32_t)) / sizeof(PnSTrampolineEntryPointBlock);

typedef struct {
    //data section
    union {
        struct {
            IMP onEntry;
            IMP onExit;
            void * pMalloc;
            void * pFree;
            int32_t nextAvailableTrampolineIndex;
        };
        int32_t placeHolder[PnSTrampolineInstructionCount];
    };//offset for instructions
    PnSTrampolineDataBlock trampolineData[NumberOfTrampolinesEntryPerPage];

    //code section
    int32_t trampolineInstructions[PnSTrampolineInstructionCount];//offset for instructions
    PnSTrampolineEntryPointBlock trampolineEntryPoints[NumberOfTrampolinesEntryPerPage];
} PnSTrampolinePage;

static_assert(sizeof(PnSTrampolineEntryPointBlock) >= sizeof(PnSTrampolineDataBlock),
              "Inconsistent entry point/data block sizes");
static_assert(sizeof(PnSTrampolinePage) == 2 * M_PAGE_SIZE,
              "Incorrect trampoline pages size");
static_assert(offsetof(PnSTrampolinePage, trampolineInstructions) == M_PAGE_SIZE,
                "Incorrect trampoline page offset");

static PnSTrampolinePage *PnSTrampolinePageAlloc(BOOL useObjcMsgSendStret)
{
    vm_address_t trampolineTemplatePage = useObjcMsgSendStret ? (vm_address_t)&pns_forwarding_trampoline_stret_page : (vm_address_t)&pns_forwarding_trampoline_page;

    vm_address_t newTrampolinePage = 0;
    kern_return_t kernReturn = KERN_SUCCESS;

    //printf( "%d %d %d %d %d\n", vm_page_size, &xt_forwarding_trampolines_start - &xt_forwarding_trampoline_page, SPLForwardingTrampolineInstructionCount*4, &xt_forwarding_trampolines_end - &xt_forwarding_trampoline_page, &xt_forwarding_trampolines_next - &xt_forwarding_trampolines_start );

    // allocate two consequent memory pages
    kernReturn = vm_allocate(mach_task_self(), &newTrampolinePage, PAGE_SIZE * 2, VM_FLAGS_ANYWHERE);
//    NSLog(@"---page size---%u", PAGE_SIZE);
    NSCAssert1(kernReturn == KERN_SUCCESS, @"vm_allocate failed", kernReturn);

    // deallocate second page where we will store our trampoline
    vm_address_t trampoline_page = newTrampolinePage + PAGE_SIZE;
    kernReturn = vm_deallocate(mach_task_self(), trampoline_page, PAGE_SIZE);
    NSCAssert1(kernReturn == KERN_SUCCESS, @"vm_deallocate failed", kernReturn);

    // trampoline page will be remapped with implementation of spl_objc_forwarding_trampoline
    vm_prot_t cur_protection, max_protection;
    kernReturn = vm_remap(mach_task_self(), &trampoline_page, PAGE_SIZE, 0, 0, mach_task_self(), trampolineTemplatePage, FALSE, &cur_protection, &max_protection, VM_INHERIT_SHARE);
    
    if(kernReturn != KERN_SUCCESS) {
        [TSPKLogger logWithTag:@"PrivacyCommonInfo" message:@"trampoline page alloc vm_remap failed"];
        return NULL;
    }

    return (PnSTrampolinePage *)newTrampolinePage;
}

static bool PnSTrampolinePageDealloc_internal(vm_address_t newDynamicPage)
{
    if (!newDynamicPage) return false;
    kern_return_t kernResult = KERN_SUCCESS;
    kernResult = vm_deallocate(current_task(), newDynamicPage, PAGE_SIZE*2);
    NSCAssert1(kernResult == KERN_SUCCESS, @"[PnSDynamicPage]::vm_deallocate failed", kernResult);
    return kernResult == KERN_SUCCESS;
}

static NSMutableArray *normalTrampolinePages = nil;
static NSMutableArray *structReturnTrampolinePages = nil;

void PnSTrampolinePageDealloc(void){
    for (NSValue * page in normalTrampolinePages) {
        PnSTrampolinePageDealloc_internal((vm_address_t)[page pointerValue]);
    }
    
    for (NSValue * page in structReturnTrampolinePages) {
        PnSTrampolinePageDealloc_internal((vm_address_t)[page pointerValue]);
    }
}

static PnSTrampolinePage *nextTrampolinePage(BOOL returnStructValue, BOOL shareMode, IMP entryImp, IMP exitImp);
static PnSTrampolinePage *nextTrampolinePage(BOOL returnStructValue, BOOL shareMode, IMP entryImp, IMP exitImp)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        normalTrampolinePages = [NSMutableArray array];
        structReturnTrampolinePages = [NSMutableArray array];
    });

    NSMutableArray *thisArray = returnStructValue ? structReturnTrampolinePages : normalTrampolinePages;
    PnSTrampolinePage *trampolinePage = NULL;
    
    if(!shareMode && entryImp && exitImp){
        for (NSValue *pageVal in thisArray) {
            PnSTrampolinePage *page = (PnSTrampolinePage *)pageVal.pointerValue;
            if(page->onEntry == entryImp && page->onExit == exitImp){
                trampolinePage = page;
                break;
            }
        }
    }else{
        trampolinePage = (PnSTrampolinePage *)[thisArray.lastObject pointerValue];
    }
    

    if (!trampolinePage || (trampolinePage->nextAvailableTrampolineIndex == NumberOfTrampolinesEntryPerPage) ) {
        trampolinePage = PnSTrampolinePageAlloc(returnStructValue);
        if (trampolinePage) {
            [thisArray addObject:[NSValue valueWithPointer:trampolinePage]];
        }
    }

    return trampolinePage;
}

PNS_EXTERN void *PnSMalloc(size_t size);
//helper functions
void *PnSMalloc(size_t size)
{
    void *p = (void*)malloc(size);
    return p;
}

PNS_EXTERN void PnSFree(void *buf);
// Used by RCTProfileTrampoline assembly file to call libc`free
void PnSFree(void *buf)
{
  free((void*)buf);
}

IMP _internal_PnSInstallTrampolineForIMP(SEL oriCmd, IMP originalImp, IMP onMyEntry, IMP onMyExit, BOOL returnsAStructValue, BOOL shareMode)
{
#ifdef __arm64__
    returnsAStructValue = NO;
#endif

    PnSTrampolinePage *trampolinePageLayout = nextTrampolinePage(returnsAStructValue, shareMode, onMyEntry, onMyExit);
    if (!trampolinePageLayout) {
        return NULL;
    }
    
    int32_t nextAvailableTrampolineIndex = trampolinePageLayout->nextAvailableTrampolineIndex;
    trampolinePageLayout->onEntry = onMyEntry;
    trampolinePageLayout->onExit = onMyExit;
    trampolinePageLayout->pMalloc = (void *)PnSMalloc;
    trampolinePageLayout->pFree = (void *)PnSFree;
    
    trampolinePageLayout->trampolineData[nextAvailableTrampolineIndex].oriCmd = oriCmd;

    trampolinePageLayout->trampolineData[nextAvailableTrampolineIndex].oriImp = originalImp;
    trampolinePageLayout->nextAvailableTrampolineIndex++;

    IMP implementation = (IMP)&trampolinePageLayout->trampolineEntryPoints[nextAvailableTrampolineIndex];

    return implementation;
}

IMP PnSInstallTrampolineForIMP(SEL oriCmd, IMP originalImp, IMP onMyEntry, IMP onMyExit, BOOL returnsAStructValue, BOOL shareMode)
{
    if (@available(iOS 10, *)) {
        static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
        os_unfair_lock_lock(&lock);
        IMP implementation = _internal_PnSInstallTrampolineForIMP(oriCmd, originalImp, onMyEntry, onMyExit, returnsAStructValue, shareMode);
        os_unfair_lock_unlock(&lock);
        return implementation;
    } else {
        static OSSpinLock lock = OS_SPINLOCK_INIT;
        OSSpinLockLock(&lock);
        IMP implementation = _internal_PnSInstallTrampolineForIMP(oriCmd, originalImp, onMyEntry, onMyExit, returnsAStructValue, shareMode);
        OSSpinLockUnlock(&lock);
        return implementation;
    }
}
