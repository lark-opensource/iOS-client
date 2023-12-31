//
//  OPLocationPrivacyAccessStatusManager.m
//  TTMicroApp
//
//  Created by laisanpin on 2021/6/3.
//

#import "OPLocationPrivacyAccessStatusManager.h"
#import "BDPPrivacyAccessNotifier.h"

@interface OPLocationPrivacyAccessStatusManager()
@property (nonatomic, assign) BOOL singleLocationStatus;
@property (nonatomic, assign) BOOL continueLocationStatus;
@end

@implementation OPLocationPrivacyAccessStatusManager
+ (instancetype)shareInstance {
    static id _locationPrivacyAccessStatusManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _locationPrivacyAccessStatusManager = [[self alloc] init];
    });
    return _locationPrivacyAccessStatusManager;
}

- (void)updateSingleLocationAccessStatus:(BOOL)isUsing {
    self.singleLocationStatus = isUsing;
    BOOL privateStatus = self.singleLocationStatus || self.continueLocationStatus;
    [self updatePrivacyAccessStatus:privateStatus];
}

- (void)updateContinueLocationAccessStatus:(BOOL)isUsing {
    self.continueLocationStatus = isUsing;
    BOOL privateStatus = self.singleLocationStatus || self.continueLocationStatus;
    [self updatePrivacyAccessStatus:privateStatus];
}

- (void)updatePrivacyAccessStatus:(BOOL)isUsing {
    [[BDPPrivacyAccessNotifier sharedNotifier] setPrivacyAccessStatus:BDPPrivacyAccessStatusLocation isUsing:isUsing];
}
@end
