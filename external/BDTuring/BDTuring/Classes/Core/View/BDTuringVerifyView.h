//
//  BDTuringVerifyView.h
//  BDTuring
//
//  Created by bob on 2019/8/29.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "BDTuring.h"

NS_ASSUME_NONNULL_BEGIN

@class WKWebView, BDTuringVerifyView, BDTuringVerifyModel;

@protocol BDTuringVerifyViewDelegate;


@interface BDTuringVerifyView : UIView


#pragma mark - BDTuringVerifyView

@property (nonatomic, strong, nullable) WKWebView *webView;
@property (nonatomic, weak, nullable) id<BDTuringVerifyViewDelegate> delegate;
@property (nonatomic, assign) long long startLoadTime;
@property (nonatomic, strong) BDTuringConfig *config;
@property (nonatomic, strong) BDTuringVerifyModel *model;

@property (nonatomic, assign) BOOL adjustViewWhenKeyboardHiden;

@property (nonatomic, assign) BOOL isShow;
@property (nonatomic, assign) BOOL autoVerify;

@property (nonatomic, assign) BDTuringVerifyStatus closeStatus;

@property (nonatomic, assign) BOOL isPreloadVerifyView;
@property (nonatomic, assign) long long startPreloadTime;
@property (nonatomic, assign) long long startRefreshTime;


- (void)addGestureForWebView;
- (void)showVerifyViewTillWebViewReady;

- (void)closeVerifyViewFromFeedbackClose;
- (void)closeVerifyViewFromFeedbackButton;
- (void)closeVerifyViewFromMask;

- (void)showVerifyView;
- (void)hideVerifyView;     /// only hide then will be dismissed
- (void)dismissVerifyView;  /// dismiss when verify end

- (void)scheduleDismissVerifyView;

- (CGPoint)subViewCenter;

@end

NS_ASSUME_NONNULL_END
