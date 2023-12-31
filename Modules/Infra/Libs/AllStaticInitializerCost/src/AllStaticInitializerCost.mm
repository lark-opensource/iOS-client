//
//  AllStaticInitializerCost.m
//  AllLoadCost
//
//  Created by CL7R on 2020/8/12.
//

#import <Foundation/Foundation.h>
#include <iostream>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <mach-o/arch.h>
#include <mach-o/getsect.h>
#include <dlfcn.h>
#include <vector>
#import <AllStaticInitializerCost/AllStaticInitializerCost-Swift.h>

@interface AllStaticInitializerCost : NSObject

@end

@implementation AllStaticInitializerCost

static NSMutableDictionary<NSString *, NSNumber *> *staticCostDic;

static double totalTime = 0;

using namespace std;

typedef uint64_t MemoryType;

static std::vector<MemoryType> *g_initializer;

static int g_cur_index;

const struct mach_header_64 *mhdr;

struct MyProgramVars {
    const void * mh;
    int *NXArgcPtr;
    const char *** NXArgvPtr;
    const char *** environPtr;
    const char ** __prognamePtr;
};

typedef void(*OriginalInitializer)(int argc, const char* argv[], const char* envp[], const char* apple[], const struct MyProgramVars* vars);

+ (void)load {
    staticCostDic = [NSMutableDictionary dictionary];
    [self queryMainImageHeader];
    hookModInitFunc();
    //5s后执行打印，确保logger正常
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self queryAllStaticCost];
    });
}

/// 查询+load耗时
+ (void)queryAllStaticCost {
    if (staticCostDic.count == 0) {
        NSLog(@"[static is zero]");
        return ;
    }
    NSArray *keyArr = [staticCostDic keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        if ([obj1 floatValue] < [obj2 floatValue]) {
            return  NSOrderedDescending;
        }
        else if ([obj1 floatValue] > [obj2 floatValue]) {
            return  NSOrderedAscending;
        }
        else {
            return NSOrderedSame;
        }
    }];
    NSString *strAll = [NSString stringWithFormat:@"[static counts = %lu，all cost = %.2f ms",staticCostDic.count,totalTime];
    [AllStaticInitializerCostSwiftBridge printLogWithInfo:strAll];
    NSLog(@"%@",strAll);
    NSString *strLoad = @"";
    for (NSString *str in keyArr) {
        strLoad = [NSString stringWithFormat:@"[static][%@] = %.2f ms",str,[staticCostDic[str] doubleValue]];
        NSLog(@"%@",strLoad);
        [AllStaticInitializerCostSwiftBridge printLogWithInfo:strLoad];
    }
}

+ (void)queryMainImageHeader {
    //获取App加载dylib的数量
    uint32_t imageCount = _dyld_image_count();
    //获取项目名称
    NSString *projectName = ((NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleExecutableKey]);
    for (uint32_t imgIndex = 0; imgIndex < imageCount; imgIndex++) {
        //获取image，并匹配
        const char *path = _dyld_get_image_name(imgIndex);
        NSString *imgPath = [NSString stringWithUTF8String:path];
        NSString *dylib = [[imgPath componentsSeparatedByString:@"/"] lastObject];
        if ([dylib isEqualToString:projectName]) {
            mhdr = (mach_header_64 *)_dyld_get_image_header(imgIndex);
            NSString *strHead = [NSString stringWithFormat:@"%p",mhdr];
            NSLog(@"[static imageHeader]%@",strHead);
            [AllStaticInitializerCostSwiftBridge printLogWithInfo:strHead];
            break;
        }
    }
}

void myModInitFunc(int argc, const char* argv[], const char* envp[], const char* apple[], const struct MyProgramVars* vars){
    ++g_cur_index;
    OriginalInitializer oriFunc = (OriginalInitializer)g_initializer->at(g_cur_index);
    Dl_info funcInfo;
    dladdr((void *)oriFunc, &funcInfo);
    CFTimeInterval startTimeSelf = CFAbsoluteTimeGetCurrent();
    oriFunc(argc,argv,envp,apple,vars);
    CFTimeInterval endTimeSelf = CFAbsoluteTimeGetCurrent();
    CFTimeInterval cost = (endTimeSelf-startTimeSelf)*1000;
    totalTime += cost;
    if (!funcInfo.dli_sname) {
        ///目前release版sname为空，暂时取内存地址，然后本地符号化
        staticCostDic[[NSString stringWithFormat:@"%p",oriFunc]] = @(cost);
    }
    else {
        staticCostDic[[NSString stringWithFormat:@"%s",funcInfo.dli_sname]] = @(cost);
    }
}

void hookModInitFunc() {
    g_initializer = new std::vector<MemoryType>();
    g_cur_index = -1;
    unsigned long size = 0;
    MemoryType *memory = (uint64_t *)getsectiondata(mhdr, "__DATA", "__mod_init_func", &size);
    for(int idx = 0; idx < size/sizeof(void*); idx++){
        MemoryType original_ptr = memory[idx];
        g_initializer->push_back(original_ptr);
        memory[idx] = (MemoryType)myModInitFunc;
    }
}

@end
