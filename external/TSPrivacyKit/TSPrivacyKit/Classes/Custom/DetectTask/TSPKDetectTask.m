//
//  TSPKDetectTask.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKDetectTask.h"

@interface TSPKDetectTask ()

@property (nonatomic, strong, nonnull) TSPKDetectEvent *detectEvent;

@end

@implementation TSPKDetectTask

- (instancetype _Nullable)initWithDetectEvent:(TSPKDetectEvent * _Nonnull)event
{
    if (self = [super init]) {
        _detectEvent = event;
        _onCurrentThread = YES;
        [self setup];
        [self decodeParams:event.detectPlanModel.ruleModel.params];
    }
    return self;
}

- (void)setup
{
    
}

- (void)decodeParams:(NSDictionary * _Nonnull)params
{
    
}

- (void)executeWithScheduleTime:(NSTimeInterval)scheduleTime
{
    
}

- (void)markTaskFinish
{
    [self.delegate detectTaskDidFinsh:self];
}

@end
