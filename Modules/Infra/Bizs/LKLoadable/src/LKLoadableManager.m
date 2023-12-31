//
//  LKLoadableManager.m
//  BootManager
//
//  Created by sniperj on 2021/4/28.
//

#import "LKLoadableManager.h"
#import "Loadable.h"
#import <objc/runtime.h>
#import <objc/message.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import <QuartzCore/CABase.h>

@interface LKLoadableManager()

+ (BOOL)filter:(const char *)name;

@end

static int LoadableFuncCallbackImpl(const char *name){
    if([LKLoadableManager filter:name])
        return 1;
    
    return 0;
}

static void LoadbleFuncRun(char *state) {
    CFTimeInterval loadStart = CFAbsoluteTimeGetCurrent();
    
    Dl_info info;
    int ret = dladdr(LoadbleFuncRun, &info);
    if(ret == 0){
        // fatal error
    }
    
#ifndef __LP64__
    const struct mach_header *mhp = (struct mach_header*)info.dli_fbase;
    unsigned long size = 0;
    uint32_t *memory = (uint32_t*)getsectiondata(mhp, PreLoadSegmentName, state, & size);
#else /* defined(__LP64__) */
    const struct mach_header_64 *mhp = (struct mach_header_64*)info.dli_fbase;
    unsigned long size = 0;
    uint64_t *memory = (uint64_t*)getsectiondata(mhp, LoadableSegmentName, state, & size);
#endif /* defined(__LP64__) */
    
    CFTimeInterval loadComplete = CFAbsoluteTimeGetCurrent();
    NSLog(@"LKLoadableManager:loadcost:%@ms",@(1000.0*(loadComplete-loadStart)));
    if(size == 0){
        NSLog(@"LKLoadableManager:empty");
        return;
    }
    
    for(int idx = 0; idx < size/sizeof(void*); ++idx){
        LoadableFunctionTemplate func = (LoadableFunctionTemplate)memory[idx];
        func(LoadableFuncCallbackImpl);
    }
    
    NSLog(@"LKLoadableManager:callcost:%@ms",@(1000.0*(CFAbsoluteTimeGetCurrent()-loadComplete)));
}

@implementation LKLoadableManager

+ (void)run:(LoadableState)state {
    switch (state) {
        case appMain:
            LoadbleFuncRun(LoadableMain);
            break;
        case didFinishLaunch:
            LoadbleFuncRun(LoadableDidFinishLaunch);
            break;
        case runloopIdle:
            LoadbleFuncRun(LoadableRunloopIdle);
            break;
        case afterFirstRender:
            LoadbleFuncRun(LoadableAfterFirstRender);
            break;
        default:
            break;
    }
}

+ (BOOL)filter:(const char *)name {
    return NO;
}

static CFTimeInterval willFinishLaunchingTime = 0;
+ (void)makeWillFinishLaunchingTime {
    willFinishLaunchingTime = CACurrentMediaTime();
}
+ (CFTimeInterval)getWillFinishLaunchingTime {
    return willFinishLaunchingTime;
}

@end
