//
//  CJPayAlertController.m
//  CJPay
//
//  Created by 尚怀军 on 2019/11/18.
//

#import "CJPayAlertController.h"
#import "UIFont+CJPay.h"
#import "UIColor+CJPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"

@implementation CJPayWindow

- (void)makeKeyWindow {
    if (@available(iOS 14.2, *)) {
        
    } else {
        [super makeKeyWindow];
    }
}

@end

@interface CJPayAlertController ()

@property (nonatomic, strong) CJPayWindow *alertWindow;

@end

@implementation CJPayAlertController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 兼容暗黑模式
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    
    // Do any additional setup after loading the view.
}

- (void)applyBindCardMessageStyleWithMessage:(NSString *)msg {
    if (!Check_ValidString(msg)) {
        return;
    }
    
    if (!Check_ValidString(self.title)) {
        return;
    }
    
    NSDictionary *titleAttributes = @{NSFontAttributeName : [UIFont cj_semiboldFontOfSize:17],
                                     NSForegroundColorAttributeName : [UIColor cj_222222ff]};
    NSMutableAttributedString *alertTitleStr = [[NSMutableAttributedString alloc] initWithString:CJString(self.title) attributes:titleAttributes];
    
    NSString *msgStr = [NSString stringWithFormat:@"(%@)", msg];
    NSDictionary *msgAttributes = @{NSFontAttributeName : [UIFont cj_semiboldFontOfSize:17],
                                     NSForegroundColorAttributeName : [UIColor cj_cacacaff]};
    NSMutableAttributedString *alertMessageStr = [[NSMutableAttributedString alloc] initWithString:CJString(msgStr) attributes:msgAttributes];
    [alertTitleStr appendAttributedString:alertMessageStr];
    [self setValue:alertTitleStr forKey:@"attributedTitle"];

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.alertWindow.hidden = YES;
    [self.alertWindow removeFromSuperview];
    self.alertWindow = nil;
}

- (CJPayWindow *)alertWindow {
    if (!_alertWindow) {
        _alertWindow = [[CJPayWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _alertWindow.rootViewController = [UIViewController new];
        _alertWindow.hidden = NO;
    }
    return _alertWindow;
}

- (void)showUse:(UIViewController *)vc {
    if (vc) {
        [vc presentViewController:self animated:YES completion:nil];
    } else {
        CJPayLogAssert(!CJ_Pad, @"pad下的弹窗都要加上referVC");
        [self.alertWindow.rootViewController presentViewController:self animated:YES completion:nil];
    }
}

@end
