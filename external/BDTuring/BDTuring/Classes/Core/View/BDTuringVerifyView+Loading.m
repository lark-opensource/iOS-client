//
//  BDTuringVerifyView+Loading.m
//  BDTuring
//
//  Created by bob on 2020/7/22.
//

#import "BDTuringVerifyView+Loading.h"
#import "BDTuringUIHelper.h"
#import "BDTuringVerifyModel.h"

@implementation BDTuringVerifyView (Loading)

@dynamic indicatorView;

- (void)startLoadingView {
    if ([BDTuringUIHelper sharedInstance].disableLoadingView || self.model.hideLoading) {
        return;
    }
    
    UIActivityIndicatorView *indicatorView = self.indicatorView;
    if (indicatorView == nil) {
        indicatorView = [self createIndicatorView];
        self.indicatorView = indicatorView;
        [self addSubview:indicatorView];
    }
    indicatorView.hidden = NO;
    [self bringSubviewToFront:indicatorView];
    [indicatorView startAnimating];
}

- (void)stopLoadingView {
    if ([BDTuringUIHelper sharedInstance].disableLoadingView || self.model.hideLoading) {
        return;
    }
    
    UIActivityIndicatorView *indicatorView = self.indicatorView;
    if (indicatorView.isAnimating) {
        [indicatorView stopAnimating];
        [indicatorView removeFromSuperview];
        self.indicatorView = nil;
    }
}

- (UIActivityIndicatorView *)createIndicatorView {
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    indicatorView.center = self.webView.center;
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    indicatorView.hidesWhenStopped = YES;

    return indicatorView;
}

@end
