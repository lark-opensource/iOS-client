//
//  NSObject+TracingPerformSelector.m
//  Timor
//
//  Created by changrong on 2020/5/24.
//

#import "NSObject+Tracing.h"
#import "BDPTracingManager.h"

@interface BDPTracingPerformSelectorArgus : NSObject
@property (nonatomic, assign) SEL aSelector;
@property (nonatomic, strong) id arg;
@property (nonatomic, strong) BDPTracing *tracing;
@end
@implementation BDPTracingPerformSelectorArgus
@end

@implementation NSObject(Tracing)

- (void)bdp_tracingPerformSelectorOnMainThread:(SEL)aSelector withObject:(id)arg waitUntilDone:(BOOL)wait {
    BDPTracingPerformSelectorArgus *args = [[BDPTracingPerformSelectorArgus alloc] init];
    args.aSelector = aSelector;
    args.arg = arg;
    args.tracing = [BDPTracingManager getThreadTracing];
    
    [self performSelectorOnMainThread:@selector(bdp_tracingDoSelectorWithArgs:) withObject:args waitUntilDone:wait];
}

- (void)bdp_tracingDoSelectorWithArgs:(BDPTracingPerformSelectorArgus *)args {
    [BDPTracingManager doBlock:^{
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:args.aSelector withObject:args.arg];
        #pragma clang diagnostic pop
    } withLinkTracing:args.tracing];
}

@end
