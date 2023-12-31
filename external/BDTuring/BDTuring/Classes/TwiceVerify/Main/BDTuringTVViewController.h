//
//  BDTuringTVViewController.h
//  BDTuring-BDTuringResource
//
//  Created by yanming.sysu on 2020/10/29.
//

#import <UIKit/UIKit.h>
#import "BDTuringTVDefine.h"
#import "BDTuringTwiceVerify.h"
#import <WebKit/WebKit.h>
#import "BDTuringPiperConstant.h"

@class BDTuringConfig;

@interface BDTuringTVViewController : UIViewController <WKNavigationDelegate>

@property (nonatomic, copy) BDTuringTVResponseCallBack _Nullable callBack;
@property (nonatomic, copy) NSString *scene;
@property (nonatomic, strong) BDTuringConfig *config;

@property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) CGFloat webViewHeight;
@property (nonatomic, assign) CGFloat webViewWidth;
@property (nonatomic, assign) CGRect oriFrame;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, assign) kBDTuringTVBlockType blockType;
@property (nonatomic, copy, nullable) BDTuringPiperOnCallback cacheCallback;

- (instancetype)initWithParams:(NSDictionary *)params;


#pragma mark place holder

- (void)presentMessageComposeViewControllerWithPhone:(NSString *)phone content:(NSString *)content;

+ (BOOL)canSendText;

@end
