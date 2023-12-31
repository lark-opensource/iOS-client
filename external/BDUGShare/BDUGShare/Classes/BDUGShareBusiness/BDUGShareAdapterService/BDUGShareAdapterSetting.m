//
//  BDUGShareAdapterSetting.m
//  Pods
//
//  Created by 张 延晋 on 3/7/15.
//
//

#import "BDUGShareAdapterSetting.h"
#import <ByteDanceKit/ByteDanceKit.h>

@interface BDUGShareAdapterSetting()

@property (nonatomic, copy) NSString * panelClassName;

@end

@implementation BDUGShareAdapterSetting

+ (instancetype)sharedService
{
    static BDUGShareAdapterSetting *setting;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        setting = [[BDUGShareAdapterSetting alloc] init];
    });
    return setting;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _panelClassName = @"BDUGActivityPanelController";
    }
    return self;
}

- (BOOL)isPadDevice
{
    return [UIDevice btd_isPadDevice];
}

- (UIViewController *)topmostViewController
{
    return [BTDResponder topViewController];
}

- (void)activityWillSharedWith:(id<BDUGActivityProtocol>)activity
{
    if ([self.commonInfoDelegate respondsToSelector:@selector(activityWillSharedWith:)]) {
        [self.commonInfoDelegate activityWillSharedWith:activity];
    }
}

- (void)activityHasSharedWith:(id<BDUGActivityProtocol>)activity error:(NSError *)error desc:(NSString *)desc
{
    NSString *logInfo = [NSString stringWithFormat:@"BDUGShare - 分享结束，渠道：%@, error: %@, desc: %@", NSStringFromClass(activity.class), error, desc];
    BDUGLoggerInfo(logInfo);
    if ([self.commonInfoDelegate respondsToSelector:@selector(activityHasSharedWith:error:desc:)]) {
        [self.commonInfoDelegate activityHasSharedWith:activity error:error desc:desc];
    }
}

- (void)setPanelClassName:(NSString *)panelClassName {
    if (0 == panelClassName.length) {
        return;
    }
    if ([_panelClassName isEqualToString:panelClassName]) {
        return;
    }
    _panelClassName = panelClassName;
}

- (NSString *)getPanelClassName {
    return _panelClassName;
}

#pragma mark - Share Item Source

- (BOOL)shouldBlockShareWithActivity:(id<BDUGActivityProtocol>)activity {
    if ([self.shareBlockDelegate respondsToSelector:@selector(shouldBlockShareWithActivity:) ]) {
        return [self.shareBlockDelegate shouldBlockShareWithActivity:activity];
    }
    return NO;
}

- (void)didBlockShareWithActivity:(id<BDUGActivityProtocol>)activity continueBlock:(void (^)(void))block {
    if ([self.shareBlockDelegate respondsToSelector:@selector(didBlockShareWithActivity:continueBlock:)]) {
        [self.shareBlockDelegate didBlockShareWithActivity:activity continueBlock:block];
    }
}

#pragma mark - share alibity

- (void)shareAbilityShowLoading
{
    if ([self.shareAbilityDelegate respondsToSelector:@selector(sharedInstance)] &&
        [[self.shareAbilityDelegate sharedInstance] respondsToSelector:@selector(shareAbilityShowLoading)]) {
        [[self.shareAbilityDelegate sharedInstance] shareAbilityShowLoading];
    }
}

- (void)shareAbilityHideLoading
{
    if ([self.shareAbilityDelegate respondsToSelector:@selector(sharedInstance)] &&
        [[self.shareAbilityDelegate sharedInstance] respondsToSelector:@selector(shareAbilityHideLoading)]) {
        [[self.shareAbilityDelegate sharedInstance] shareAbilityHideLoading];
    }
}

@end
