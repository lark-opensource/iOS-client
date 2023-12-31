
/*!@header HMDServiceContextDispatchMain.h
   @discussion Protect 和 HMDDispatchMain 模块通信部分
   后续会和 ServiceContext 融合下掉
 */

#import <Foundation/Foundation.h>
#import "HMDPublicMacro.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMDMainThreadDispatchProtocol <NSObject>
@required

+ (instancetype)sharedInstance;

@property(atomic, readwrite, assign) BOOL enable;

-(void)dispatchMainThreadMethods:(NSArray<NSString *> *)methods;

@end

HMD_EXTERN id<HMDMainThreadDispatchProtocol> _Nullable HMDServiceContext_getMainThreadDispatch(void);

NS_ASSUME_NONNULL_END
