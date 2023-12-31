//
//  BDPTracingManager+Gadget.h
//  TTMicroApp
//
//  Created by justin on 2022/12/19.
//

#import <OPFoundation/BDPTracingManager.h>

NS_ASSUME_NONNULL_BEGIN
@protocol OPMicroAppJSRuntimeProtocol;
@class BDPAppPage;

@interface BDPTracingManager (Gadget)

/**
 * 绑定一个新的tracing到jsRuntime
 */
- (BDPTracing *)generateTracingByJSRuntime:(id<OPMicroAppJSRuntimeProtocol>)jsRuntime;

/**
 * 绑定一个新的tracing到AppPage
 */
- (BDPTracing *)generateTracingByAppPage:(BDPAppPage *)appPage;


- (nullable BDPTracing *)getTracingByJSRuntime:(id<OPMicroAppJSRuntimeProtocol>)jsRuntime;

- (nullable BDPTracing *)getTracingByAppPage:(BDPAppPage *)appPage;



@end

NS_ASSUME_NONNULL_END
