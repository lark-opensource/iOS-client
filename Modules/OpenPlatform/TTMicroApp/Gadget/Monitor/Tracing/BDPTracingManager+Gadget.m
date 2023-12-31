//
//  BDPTracingManager+Gadget.m
//  TTMicroApp
//
//  Created by justin on 2022/12/19.
//

#import "BDPTracingManager+Gadget.h"
#import "BDPAppPage+BAPTracing.h"
#import "OPMicroAppJSRuntimeProtocol.h"


@implementation BDPTracingManager (Gadget)

/// 挂载Tracing到JSRuntime，详见.h
- (BDPTracing *)generateTracingByJSRuntime:(id<OPMicroAppJSRuntimeProtocol>)jsRuntime {
    [jsRuntime bindTracing:[self generateTracing]];
    return [self getTracingByJSRuntime:jsRuntime];
}

/// 挂载Tracing到AppPage，详见.h
- (BDPTracing *)generateTracingByAppPage:(BDPAppPage *)appPage {
    [appPage bap_bindTracing:[self generateTracing]];
    return [self getTracingByAppPage:appPage];
}


/// 通过JSRuntime获取tracing，详见.h
- (nullable BDPTracing *)getTracingByJSRuntime:(id<OPMicroAppJSRuntimeProtocol>)jsRuntime {
    return jsRuntime.trace;
}

/// 通过AppPage获取tracing，详见.h
- (nullable BDPTracing *)getTracingByAppPage:(BDPAppPage *)appPage {
    return appPage.bap_trace;
}

@end
