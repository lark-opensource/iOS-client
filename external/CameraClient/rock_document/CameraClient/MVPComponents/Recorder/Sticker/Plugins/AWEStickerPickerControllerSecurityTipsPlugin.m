//
//  AWEStickerPickerControllerSecurityTipsPlugin.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/27.
//

#import "AWEStickerPickerControllerSecurityTipsPlugin.h"
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIImageView+ACCAddtions.h>
#import "AWEPropSecurityTipsHelper.h"

@interface AWEStickerPickerControllerSecurityTipsPlugin()
@property (nonatomic, strong) UIImageView *iconImageView;
@end

@implementation AWEStickerPickerControllerSecurityTipsPlugin

- (void)controllerViewDidLoad:(AWEStickerPickerController *)controller
{
    [self.layoutManager addSecurityTipsView:self.iconImageView];
}

- (void)controller:(AWEStickerPickerController *)controller willShowOnView:(UIView *)view
{
    self.iconImageView.hidden = ![AWEPropSecurityTipsHelper shouldShowSecurityTips];
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.userInteractionEnabled = YES;
        _iconImageView.image = ACCResourceImage(@"icon_security_tips");
        _iconImageView.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-15, -15, -15, -15);
        _iconImageView.hidden = ![AWEPropSecurityTipsHelper shouldShowSecurityTips];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(handleTapOnSecurityTips)];
        [_iconImageView addGestureRecognizer:tap];
    }
    return _iconImageView;
}

- (void)handleTapOnSecurityTips
{
    @weakify(self)
    [ACCAlert() showAlertWithTitle:nil
                       description:@"道具中的人脸特效仅用做本地效果实现，不会上传和采集你的人脸特征"
                             image:nil
                 actionButtonTitle:nil
                 cancelButtonTitle:@"我知道了"
                       actionBlock:nil
                       cancelBlock:^{
        @strongify(self)
        self.iconImageView.hidden = YES;
        [AWEPropSecurityTipsHelper handleSecurityTipsDisplayed];
    }];
}
@end
