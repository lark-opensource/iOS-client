//
//  CJPayHybridView+debug.m
//  CJPaySandBox
//
//  Created by 高航 on 2023/3/24.
//

#import "CJPayHybridView+debug.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <XDebugger/HDTDebugTagLauncher.h>
#import <CJPay/CJPaySDKMacro.h>
#import <Masonry/Masonry.h>
#import <HybridKit/HybridSchemaParam.h>

@implementation CJPayHybridView (debug)

+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"p_setTag")
                               with:@selector(debug_setTag)];
}

- (void)debug_setTag {
    NSString *keyPath = @"kitView.lynxView";
    NSString *name = @"CJ-Lynx";
    if (self.engineType == HybridEngineTypeWeb) {
        keyPath = @"kitView.webView";
        name = @"CJ-Web";
    }
    [HDTDebugTagLauncher.sharedInstance addDebugTagForContainerView:self tellingMeLynxViewOrWebViewKeyPath:keyPath showingContainerName:name];
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj && [obj isKindOfClass:UILabel.class]) {
            UILabel *tag = (UILabel *)obj;
            if ([tag.text isEqualToString:name]) {
                [obj mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(20);
                    make.right.equalTo(self);
                    make.top.equalTo(self).offset(40);
                }];
            }
        }
    }];
}

@end
