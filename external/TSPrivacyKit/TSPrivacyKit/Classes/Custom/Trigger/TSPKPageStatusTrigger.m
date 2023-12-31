//
//  TSPKPageStatusTrigger.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKPageStatusTrigger.h"
#import "TSPKUtils.h"
#import "TSPKLogger.h"
#import "TSPKDelayDetectSchduler.h"
#import "TSPrivacyKitConstants.h"

@interface TSPKPageStatusTrigger () <TSPKDelayDetectDelegate>

@property (nonatomic, copy) NSString *pageName;
@property (nonatomic) BOOL carePageAppear;
@property (nonatomic) BOOL carePageDisappear;
@property (nonatomic) double detectTimeDelay;
@property (nonatomic, assign) BOOL isGrayScale;
@property (nonatomic, strong) TSPKDelayDetectSchduler *delayScheduler;

@end

@implementation TSPKPageStatusTrigger

- (void)decodeParams:(NSDictionary *_Nonnull)params
{
    self.pageName = params[@"pageClassName"];
    
    if (params[@"isGrayScale"]) {
        self.isGrayScale = [params[@"isGrayScale"] boolValue];
    } else {
        self.isGrayScale = NO;
    }
    
    TSPKDelayDetectModel *delayDetectModel = [TSPKDelayDetectModel new];
    delayDetectModel.detectTimeDelay = MAX(0, [params[@"timeDelay"] doubleValue]);

    NSString *pageStatus = (NSString*)params[@"pageStatus"];
    if ([pageStatus isEqualToString:@"Appear"]) {
        self.carePageAppear = YES;
        self.carePageDisappear = NO;
        delayDetectModel.isAnchorPageCheck = params[@"anchorPageCheck"] != nil ? [params[@"anchorPageCheck"] boolValue] : YES;
    } else if ([pageStatus isEqualToString:@"Disappear"]) {
        self.carePageAppear = NO;
        self.carePageDisappear = YES;
        delayDetectModel.isAnchorPageCheck = NO;
    }
    
    delayDetectModel.isCancelPrevDetectWhenStartNewDetect = NO;
    
    self.delayScheduler = [[TSPKDelayDetectSchduler alloc] initWithDelayDetectModel:delayDetectModel delegate:self];
}

- (void)setup
{
    [self addNotifications];
}

- (void)dealloc
{
    [self removeNotifications];
    [self cancelDetectAction];
}

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewDidAppear object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewDidDisappear object:nil];
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handlePageStatusChangeNotification:(NSNotification *_Nonnull)notification
{
    if (notification.userInfo && notification.userInfo[TSPKPageNameKey]) {
        NSString *pageName = (NSString *)notification.userInfo[TSPKPageNameKey];
        if ([notification.name isEqualToString:TSPKViewDidAppear]) {
            [self pageDidAppear:pageName];
        } else if ([notification.name isEqualToString:TSPKViewDidDisappear]) {
            [self pageDidDisappear:pageName];
        }
    }
}

- (void)pageDidAppear:(NSString *_Nonnull)pageName
{
    BOOL isInterestPage = [self.pageName isEqualToString:pageName];

    if (!isInterestPage) {
        return;
    }
    [self pageStatusChangeForDetectAction:self.carePageAppear];
}

- (void)pageDidDisappear:(NSString *_Nonnull)pageName
{
    BOOL isInterestPage = [self.pageName isEqualToString:pageName];

    if (!isInterestPage) {
        return;
    }
    [self pageStatusChangeForDetectAction:self.carePageDisappear];
}

- (void)pageStatusChangeForDetectAction:(BOOL)shouldAction
{
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state != UIApplicationStateActive) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"PageStatusTrigger: app isn't active, return"];
        return;
    }

    if (shouldAction) {
        [self scheduleDetectAction];
    } else {
        [self cancelDetectAction];
    }
}

- (void)scheduleDetectAction
{
    if (!self.detectAction) {
        return;
    }
    
    [self.delayScheduler startDelayDetect];
}

- (void)cancelDetectAction
{
    [self.delayScheduler stopDelayDetect];
}

#pragma mark - TSPKDelayDetectDelegate

- (nullable NSString *)getComparePage {
    return self.pageName;
}

- (void)executeDetectWithActualTimeGap:(NSTimeInterval)actualTimeGap {
    TSPKDetectCondition *condition = [TSPKDetectCondition new];
    condition.timeGapToCancelDetect = actualTimeGap;//timeGap >= detectTimeDelay! it is the actual gap between begining of detect task to the task schedule
    
    TSPKDetectEvent *event = [TSPKDetectEvent new];
    event.condition = condition;
    !self.detectAction ?: self.detectAction(event);
}

@end
