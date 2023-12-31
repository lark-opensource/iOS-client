//
//  BDPMacroUtils.h
//  Timor
//
//  Created by 王浩宇 on 2018/11/12.
//

//#import "BDPDebugMacro.h"
#import <ECOInfra/OPMacroUtils.h>

#ifndef BDPMarcoUtils_h
#define BDPMarcoUtils_h
#import "BDPTracingManager.h"

#pragma mark - Uglify
/*-----------------------------------------------*/
//               Uglify - 混淆专用字段
/*-----------------------------------------------*/
#ifndef BDPStringUglify
    #define BDPStringUglify
    #define BDPStringUglify_microapp BDP_STRING_CONCAT(@"mic", @"roa", @"pp")  /// microapp
    #define BDPStringUglify_micro_app BDP_STRING_CONCAT(@"mic", @"ro_a", @"pp") /// micro_app
    #define BDPStringUglify_mini_program BDP_STRING_CONCAT(@"min", @"i_pro", @"gram") // mini_program
#endif

#pragma mark - Block
/*-----------------------------------------------*/
//                Block - 代码块执行
/*-----------------------------------------------*/
#ifndef BLOCK_EXEC
    #define BLOCK_EXEC(block, ...)\
    if (block) {\
        block(__VA_ARGS__);\
    };
#endif

#define BLOCK_EXEC_IN_MAIN(blk, args...) {\
if (blk) {\
dispatch_block_t tracingBlock = [BDPTracingManager convertTracingBlock:^{ blk(args); }];\
if ([NSThread isMainThread]) {\
tracingBlock();\
} else {\
dispatch_async(dispatch_get_main_queue(), tracingBlock);\
}\
}\
}

#pragma mark - Application Plugin
/*-----------------------------------------------*/
//     Application Plugin - 宿主应用程序代理插件
/*-----------------------------------------------*/
#ifndef BDPPlugin
#define BDPPlugin(plugin, class) id<class> plugin = (id<class>)[[[BDPTimorClient sharedClient] plugin] sharedPlugin]
#endif

#pragma mark - Others
/*-----------------------------------------------*/
//                  Others - 其他
/*-----------------------------------------------*/
#if DEBUG
#define BDPDebugNSLog( s, ... ) NSLog(s, ##__VA_ARGS__)
#else
#define BDPDebugNSLog( s, ... )
#endif


#ifndef RELEASE_ARRAY_ELEMENTS_SEPARATE_MAIN_THREADS_DELAY_SECS
    #define RELEASE_ARRAY_ELEMENTS_SEPARATE_MAIN_THREADS_DELAY_SECS(array, secs) \
    if(![array isKindOfClass:[NSArray class]]) { return; }\
    for (NSObject * o in array) { \
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(secs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ \
            NSObject *retainObj = o;\
            retainObj = nil;\
        });\
    }
#endif


// FUNCTION
// 注意不要插入非nil对象!!!
#define BDP_STRING_CONCAT(...) ([@[__VA_ARGS__] componentsJoinedByString:@""])

#define LOCK(semaphore, ...) dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);\
__VA_ARGS__;\
dispatch_semaphore_signal(semaphore);

#endif /* BDPMarcoUtils_h */
