//
//  CJPayCallFeatureCollector.m
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/22.
//

#import "CJPayCallFeatureCollector.h"
#import "CJPayFeatureCollectorManager.h"
#import <CallKit/CallKit.h>
#import "CJPayUIMacro.h"

@interface CJPayCallFeatureCollector()<CXCallObserverDelegate>


@property (nonatomic, strong) CXCallObserver *callObserver;
@property (nonatomic, assign) BOOL isCalling;

@end

@implementation CJPayCallFeatureCollector

@synthesize recordManager;

- (instancetype)init {
    self = [super init];
    self.isCalling = NO;
    self.callObserver = [[CXCallObserver alloc] init];
    if (self.callObserver.calls.count > 0) {
        @CJWeakify(self);
        [self.callObserver.calls enumerateObjectsUsingBlock:^(CXCall * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @CJStrongify(self);
            if (obj.hasConnected && !obj.hasEnded) {
                self.isCalling = YES;
            }
        }];
    }
    [self.callObserver setDelegate:self queue:dispatch_get_main_queue()];
    return self;
}

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call {
    self.isCalling = call.hasConnected && !call.hasEnded;
}

- (void)beginCollect {
    
}

- (void)endCollect {
    
}

- (NSDictionary *)buildDeviceParams {
    return @{
        @"is_calling" : @(self.isCalling)
    };
}

@end
