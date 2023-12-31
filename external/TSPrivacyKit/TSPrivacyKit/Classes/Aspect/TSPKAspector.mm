//
//  TSPKAspector.m
//  TestMe
//
//  Created by bytedance on 2021/12/4.
//

#import "TSPKAspector.h"
#import "TSPKAspectTrampolinePage.h"
#import <objc/runtime.h>

#import <dlfcn.h>

static IMP onMyEntry(id arg1, SEL cmd, SEL oriCmd,IMP oriImp, void* retAddress);
static IMP onMyEntry(id arg1, SEL cmd, SEL oriCmd, IMP oriImp, void* retAddress)
{
//    NSLog(@"onMyEntry %@-%@", arg1, NSStringFromSelector(oriCmd));
    Dl_info info;
    memset(&info, 0, sizeof(info));
    if (dladdr(retAddress, &info) != 0)
    {
//        printf("dli_fname=%s\ndli_fbase=%p\ndli_sname=%s\ndl_saddr=%p\n", info.dli_fname, info.dli_fbase, info.dli_sname, info.dli_saddr);
            
//        struct mach_header_64 *pheader = (struct mach_header_64*)info.dli_fbase;
        
    }
    return oriImp;
}

static void onMyExit(id arg1, SEL cmd, SEL oriCmd);
static void onMyExit(id arg1, SEL cmd, SEL oriCmd)
{
//    NSLog(@"onMyExit %@-%@", arg1, NSStringFromSelector(oriCmd));
}


@interface TSPKAspector()
@property(assign, atomic)IMP onEntry;
@property(assign, atomic)IMP onExit;
+ (instancetype)sharedInstance;
@end

@implementation TSPKAspector
- (instancetype)initWithEntry:(IMP)onEntry Exit:(IMP)onExit{
    if (self = [super init]) {
        self.onEntry = (IMP)onEntry;
        self.onExit = (IMP)onExit;
    }
    return self;
}

+(instancetype)sharedInstance{
    static TSPKAspector *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TSPKAspector alloc] initWithEntry:(IMP)onMyEntry Exit:(IMP)onMyExit];
    });
    return instance;
}

+ (void)setOnEntry:(IMP)entryFunc{
    [[TSPKAspector sharedInstance]setOnEntry:entryFunc];
}

+ (void)setOnExit:(IMP)exitFunc{
    [[TSPKAspector sharedInstance]setOnExit:exitFunc];
}

+ (BOOL)swizzleInstanceMethod:(Class)cls Method:(SEL)origSelector ReturnStruct:(BOOL)returnsAStructValue{
    return [[TSPKAspector sharedInstance]swizzleInstanceMethod:cls Method:origSelector ReturnStruct:returnsAStructValue ShareMode:YES];
}

+ (BOOL)swizzleClassMethod:(Class)cls Method:(SEL)origSelector ReturnStruct:(BOOL)returnsAStructValue{
    return [[TSPKAspector sharedInstance]swizzleClassMethod:cls Method:origSelector ReturnStruct:returnsAStructValue ShareMode:YES];
}

- (BOOL)swizzleInstanceMethod:(Class)cls Method:(SEL)origSelector ReturnStruct:(BOOL)returnsAStructValue
{
    return [self swizzleInstanceMethod:cls Method:origSelector ReturnStruct:returnsAStructValue ShareMode:NO];
}

- (BOOL)swizzleClassMethod:(Class)cls Method:(SEL)origSelector ReturnStruct:(BOOL)returnsAStructValue
{
    return [self swizzleClassMethod:cls Method:origSelector ReturnStruct:returnsAStructValue ShareMode:NO];
}

- (BOOL)swizzleInstanceMethod:(Class)cls Method:(SEL)origSelector ReturnStruct:(BOOL)returnsAStructValue ShareMode:(BOOL)shareMode
{
    Method originalMethod = class_getInstanceMethod(cls, origSelector);
    if (!originalMethod) {
        return NO;
    }
    IMP oriImp = method_getImplementation(originalMethod);
    IMP newImp = PnSInstallTrampolineForIMP(origSelector, oriImp, self.onEntry, self.onExit, returnsAStructValue, shareMode);
    if(!newImp){
        return NO;
    }
    
    if (class_addMethod(cls,
                        origSelector,
                        newImp,
                        method_getTypeEncoding(originalMethod)) ) {
        
    } else {
        class_replaceMethod(cls,
                            origSelector,
                            newImp,
                            method_getTypeEncoding(originalMethod));
    }
    
    return YES;
}

- (BOOL)swizzleClassMethod:(Class)cls Method:(SEL)origSelector ReturnStruct:(BOOL)returnsAStructValue ShareMode:(BOOL)shareMode
{
    Method originalMethod = class_getClassMethod(cls, origSelector);
    if (!originalMethod) {
        return NO;
    }
    IMP oriImp = method_getImplementation(originalMethod);
    IMP newImp = PnSInstallTrampolineForIMP(origSelector, oriImp, self.onEntry, self.onExit, returnsAStructValue, shareMode);
    if(!newImp){
        return NO;
    }
    
    Class metacls = objc_getMetaClass(NSStringFromClass(cls).UTF8String);
    if (class_addMethod(metacls,
                        origSelector,
                        newImp,
                        method_getTypeEncoding(originalMethod)) ) {
        
    } else {
        method_setImplementation(originalMethod, (IMP)newImp);
    }
    return YES;
}

- (void)dealloc{
    PnSTrampolinePageDealloc();
}
@end
