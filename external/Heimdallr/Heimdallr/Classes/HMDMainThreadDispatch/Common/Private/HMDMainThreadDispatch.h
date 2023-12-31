/*!@header HMDMainThreadDispatch
 * @abstract HOOK 框架，将子线程调用 UI 方法 dispatch 到主线程执行
 */

#import <Foundation/Foundation.h>
#import "HMDServiceContextMainThreadDispatch.h"

@interface HMDMainThreadDispatch: NSObject <HMDMainThreadDispatchProtocol>

+ (instancetype)sharedInstance;

@property(atomic, readwrite, assign) BOOL enable;

-(void)dispatchMainThreadMethods:(NSArray<NSString *> *)methods;

@end
