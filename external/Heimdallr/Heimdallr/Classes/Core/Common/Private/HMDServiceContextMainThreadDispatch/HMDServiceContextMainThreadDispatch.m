
/*!@file HMDServiceContextDispatchMain.m
   @discussion Protect 和 HMDDispatchMain 模块通信部分
   后续会和 ServiceContext 融合下掉
 */

#import "HMDServiceContextMainThreadDispatch.h"
#import "HMDDynamicCall.h"

id<HMDMainThreadDispatchProtocol> _Nullable HMDServiceContext_getMainThreadDispatch(void) {
    static id<HMDMainThreadDispatchProtocol> _Nullable shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = DC_CL(HMDMainThreadDispatch, sharedInstance);
    });
    return shared;
}
