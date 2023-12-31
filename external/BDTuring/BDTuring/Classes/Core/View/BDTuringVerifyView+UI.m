//
//  BDTuringVerifyView+UI.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView+UI.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringVerifyConstant.h"
#import "BDTuringMacro.h"

@implementation BDTuringVerifyView (UI)

- (NSDictionary *)customTheme {
    return @{};
}

- (NSDictionary *)customText {
    return @{};
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self adjustWebViewPosition];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGSize parentSize = frame.size;
    self.webView.center = CGPointMake(parentSize.width/2, parentSize.height/2);
}

- (void)adjustWebViewPosition {
    CGSize parentSize = self.frame.size;
    self.webView.center = CGPointMake(parentSize.width/2, parentSize.height/2);
}

- (void)handleDialogSize:(NSDictionary *)params {
    CGFloat webViewWidth = MAX([params turing_doubleValueForKey:kBDTuringVerifyParamWidth], BDTuringVerifyMinSize);
    CGFloat webViewHeight = MAX([params turing_doubleValueForKey:kBDTuringVerifyParamHeight], BDTuringVerifyMinSize);
    [self adjustWebViewPosition];
    [self setAnimationFrame:relativeFrame(webViewWidth, webViewHeight, self.frame.size)];
}

- (void)setAnimationFrame:(CGRect)frame {
    if (!self.webView.isHidden == YES) {
        self.webView.translatesAutoresizingMaskIntoConstraints = YES;
        [UIView animateWithDuration:0.3 animations:^{
            self.webView.frame = frame;
        } completion:^(BOOL finished) {
            self.webView.translatesAutoresizingMaskIntoConstraints = NO;
        }];
    } else {
        self.webView.frame = frame;
    }
}


static CGRect relativeFrame(CGFloat width, CGFloat height, CGSize size) {
    CGFloat centerX = size.width / 2;
    CGFloat centerY = size.height / 2;
    return CGRectMake(centerX - width / 2, centerY - height / 2, width, height);
}

@end
