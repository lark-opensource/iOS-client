//
//  BDTuring+Notification.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuring+Notification.h"
#import "BDTuring+Private.h"
#import "BDTuringEventService.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringVerifyConstant.h"
#import "BDTuringVerifyView+Piper.h"
#import "BDTuringUIHelper.h"
#import "BDTuringUtility.h"
#import "BDTuringSettings.h"
#import "BDTuringEventConstant.h"

@implementation BDTuring (Notification)

#pragma mark - Notification

- (void)onWillChangeStatusBarOrientation:(NSNotification *)not {
    UIInterfaceOrientation orientation = [[not.userInfo objectForKey:UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    NSInteger orientationValue = (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) ? 2 : 1;
    NSDictionary *param = @{BDTuringEventParamResult : @(orientationValue)};
    NSDictionary *jsbParam = @{kBDTuringOrientation: @(orientationValue)};
    BDTuringUIHelper *helper = [BDTuringUIHelper sharedInstance];
    if (!helper.turingForbidLandscape && helper.supportLandscape && self.isShowVerifyView) {
        [self.verifyView onOrientationChanged:jsbParam];
    }
    [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNameOrientationChange data:param];
}

- (void)onDidEnterBackground {
    if (self.isShowVerifyView) {
        NSMutableDictionary *param = [NSMutableDictionary new];
        long long duration = turing_duration_ms(self.verifyView.startLoadTime);
        [param setValue:@(duration) forKey:kBDTuringDuration];
        [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNameBackground data:param];
    }
}

- (void)onWillEnterForeground {
    
}

@end
