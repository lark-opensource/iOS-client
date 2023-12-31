//
//  CJPayBindCardRetainInfo.m
//  Pods
//
//  Created by youerwei on 2021/9/9.
//

#import "CJPayBindCardRetainInfo.h"
#import "CJPayBindCardRetainPopUpViewController.h"
#import "CJPayDyTextPopUpViewController.h"
#import "CJPayMultiBankVoucherView.h"
#import <ByteDanceKit/UIImage+BTDAdditions.h>

@implementation CJPayBindCardRetainInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"title": @"title",
        @"iconUrls": @"icon_urls",
        @"msg": @"msg",
        @"creditMsg": @"credit_msg",
        @"color": @"color",
        @"bannerTitle": @"pic_title",
        @"bannerMsg": @"pic_msg",
        @"bannerUrl": @"pic_url",
        @"defaultChecked": @"default_checked",
        @"controlFrequencyStr": @"is_control_frequency",
        @"securityUrl": @"jump_url",
        @"buttonMsg" : @"button_msg",
        @"isNeedSaveUserInfo": @"need_save_user_info"
    }];
}
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (UIView *)generateRetainView {
    UIView *view = [UIView new];
    UILabel *titleLabel = [self p_titleLabel];
    CJPayMultiBankVoucherView *voucherView = [self p_bankVoucherView];
    [view addSubview:titleLabel];
    [view addSubview:voucherView];
    
    CJPayMasMaker(titleLabel, {
        make.top.equalTo(view).offset(24);
        make.centerX.equalTo(view);
        make.left.right.equalTo(view).inset(20);
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(24));
    });
    CJPayMasMaker(voucherView, {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(view).inset(20);
        make.bottom.equalTo(view).offset(-24);
    });
    return view;
}

- (UILabel *)p_titleLabel {
    UILabel *titleLabel = [UILabel new];
    titleLabel.textColor = [UIColor cj_161823ff];
    titleLabel.font = [UIFont cj_boldFontOfSize:17];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.text = self.title;
    return titleLabel;
}

- (CJPayMultiBankVoucherView *)p_bankVoucherView {
    CJPayMultiBankVoucherView *voucherView = [CJPayMultiBankVoucherView new];
    NSArray *stringArray = [self.msg componentsSeparatedByString:@"$"];
    NSString *voucherDesc = @"";
    NSString *voucherDetail = @"";
    id object = [stringArray cj_objectAtIndex:0];
    if ([object isKindOfClass:[NSString class]]) {
        voucherDesc = (NSString *)object;
    }
    object = [stringArray cj_objectAtIndex:1];
    if ([object isKindOfClass:[NSString class]]) {
        voucherDetail = (NSString *)object;
    }
//    self.activityTitle = voucherDetail;
    NSArray *iconArray = [self.iconUrls componentsSeparatedByString:@","];

    [voucherView updateWithUrls:iconArray
                    voucherDesc:voucherDesc
                  voucherDetail:voucherDetail
                   voucherColor:[UIColor cj_colorWithHexString:self.color]];
    return voucherView;
}

- (NSArray<UIImageView *> *)p_voucherViewArray {
    NSString *voucherMsg = [self.cardType isEqualToString:@"CREDIT"] ? self.creditMsg : self.msg;
    NSArray<NSString *> *vouchers = [voucherMsg componentsSeparatedByString:@"&"];
    NSMutableArray *imageViewArray = [NSMutableArray array];
    [vouchers enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImageView *itemView = [self p_buildVoucherItemViewWithMsg:obj];
        if (itemView) {
            [imageViewArray addObject:itemView];
        }
    }];
    return [imageViewArray copy];
}

- (UIImageView *)p_buildVoucherItemViewWithMsg:(NSString *)msg {
    if (!Check_ValidString(msg)) {
        return nil;
    }
    UIImageView *imageView = [UIImageView new];
    imageView.layer.cornerRadius = 8;
    UILabel *voucherLabel = [UILabel new];
    voucherLabel.textColor = [UIColor cj_fe2c55ff];
    voucherLabel.font = [UIFont cj_boldFontOfSize:14];
    voucherLabel.textAlignment = NSTextAlignmentCenter;
    voucherLabel.text = msg;
    [imageView addSubview:voucherLabel];
    UIImage *image = [UIImage cj_imageWithName:@"cj_bindcard_retain_voucher_icon"];
    [imageView setImage:[UIImage btd_centerStrechedResourceImage:image]];
    
    CJPayMasMaker(voucherLabel, {
        make.center.equalTo(imageView);
        make.left.right.equalTo(imageView).inset(16);
    });
    return imageView;
}

@end
