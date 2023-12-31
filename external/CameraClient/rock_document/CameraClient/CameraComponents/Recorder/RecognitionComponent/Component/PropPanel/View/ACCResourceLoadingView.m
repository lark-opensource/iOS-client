//
//  ACCResourceLoadingView.m
//  AWEStudioService-Pods-Aweme
//
//  Created by liujinze on 2021/3/29.
//

#import "ACCResourceLoadingView.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreativeKit/ACCMacros.h>

static const CGFloat kShowCancelDelayTime = 5.0;

@interface ACCResourceLoadingView ()

@property (nonatomic, strong) id<ACCTextLoadingViewProtcol> loadingView;
@property (nonatomic, assign, readwrite) BOOL isShowing;

@end
   
@implementation ACCResourceLoadingView

#pragma mark - public
- (void)startLoadingWithTitle:(NSString *)title onView:(UIView *)view closeBlock:(dispatch_block_t)closeBlock
{
    self.isShowing = YES;
    @weakify(self);
    self.loadingView = [ACCLoading() showTextLoadingOnView:view title:title animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kShowCancelDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        if (self.isShowing == NO) {
            return;
        }
        [self.loadingView showCloseBtn:YES closeBlock:^{
            @strongify(self);
            ACCBLOCK_INVOKE(closeBlock);
            self.isShowing = NO;
            [self.loadingView dismissWithAnimated:NO];
        }];
    });
}

- (void)stopLoading
{
    self.isShowing = NO;
    [self.loadingView dismissWithAnimated:NO];
}

- (void)updateProgressTitle:(NSString *)title
{
    [self.loadingView acc_updateTitle:title];
}

@end
