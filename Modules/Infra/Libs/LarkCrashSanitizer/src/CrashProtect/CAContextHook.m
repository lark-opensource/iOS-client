#import <objc/runtime.h>
#import <LarkFoundation/LKEncryptionTool.h>
#import <UIKit/UIKit.h>
#import "LKHookUtil.h"
#import <LKLoadable/Loadable.h>

@interface CAContextHook: NSObject

@end

@implementation CAContextHook

+ (id)remoteContext:(id)arg1
{
    id result = [CAContextHook remoteContext:arg1];
    if (result) {
        return result;
    } else {
        // lint:disable:next lark_storage_check
        [@"CAContextImpl_crash" writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Documents/logs/contextImpl.txt"] atomically:YES encoding:4 error:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id r = [[NSClassFromString(@"CAContextImpl") alloc] performSelector:NSSelectorFromString(@"initRemoteWithOptions:") withObject:arg1];
#pragma clang diagnostic pop
        return r;
    }
}
@end

/*
 *fix bug: https://fabric.io/bytedance-ee-ios/ios/apps/com.bytedance.ee.inhouse.larkone/issues/5c188092f8b88c29633c53d6?time=last-thirty-days
 具体排查文档链接: https://bytedance.feishu.cn/space/doc/doccnewuG6RMI9AnPqPbPK
 */
LoadableRunloopIdleFuncBegin(CAContextHook)
SwizzleMethod(NSClassFromString(@"CAContext"), NSSelectorFromString(@"remoteContextWithOptions:"), [CAContextHook class], @selector(remoteContext:));
LoadableRunloopIdleFuncEnd(CAContextHook)
