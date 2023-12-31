//
//  CJPayLynxViewContext.m
//  Aweme_xiaohong
//
//  Created by wangxiaohong on 2023/3/2.
//

#import "CJPayLynxViewContext.h"

#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"

#import <Puzzle/IESHYHybridContainerConfig.h>
#import <Puzzle/PuzzleContext.h>
#import <Puzzle/PuzzleHybridContainer.h>

@implementation CJPayLynxViewContext

- (void)viewWillCreated:(id<IESHYHybridViewProtocol>)kitView {
    [self.delegate viewWillCreated];
}

- (void)viewDidCreated:(id<IESHYHybridViewProtocol>)kitView {
    [self.delegate viewDidCreated];
}

- (void)viewDidChangeIntrinsicContentSize:(CGSize)size {//修改大小时会触发该回调
    [self.delegate viewDidChangeIntrinsicContentSize:size];
}

- (void)viewDidStartLoading {
    [self.delegate viewDidStartLoading];
}

- (void)viewDidFirstScreen {
    [self.delegate viewDidFirstScreen];
}

- (void)viewDidFinishLoadWithURL:(NSString *_Nullable)url {
    [self.delegate viewDidFinishLoadWithURL:url];
}

- (void)viewDidUpdate {
    [self.delegate viewDidUpdate];
}

// 用于lynx页面刷新立即回调，承接BDLynxView的同名协议并继续往外抛
- (void)viewDidPageUpdate {
    [self.delegate viewDidPageUpdate];
}

//on exception or error
- (void)viewDidRecieveError:(NSError *_Nullable)error {
    [self.delegate viewDidRecieveError:error];
}

//did load fail(Lynx fallback & webview didFailProvisionalNavigation)
- (void)viewDidLoadFailedWithUrl:(NSString *_Nullable)url error:(NSError *_Nullable)error {
    [self.delegate viewDidLoadFailedWithUrl:url error:error];
}

@end
