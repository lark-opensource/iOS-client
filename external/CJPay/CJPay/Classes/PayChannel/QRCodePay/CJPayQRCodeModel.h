//
// Created by 易培淮 on 2020/10/15.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN


@interface CJPayShareImageModel : JSONModel

@property(nonatomic, copy) NSString *payeeName;//收款方主体名称
@property(nonatomic, copy) NSString *userNameDesc;//业务购买用户说明
@property(nonatomic, copy) NSString *validityDesc;//图片允许扫码有效期说明

@end

@protocol CJPayShareImageModel;
@interface CJPayQRCodeModel : JSONModel

@property(nonatomic, copy) NSString *imageUrl;//二维码图片地址
@property(nonatomic, copy) NSString *logo;//二维码内嵌Logo
@property(nonatomic, copy) NSString *themeColor;//主题颜色(暂不启用)
@property(nonatomic, assign) BOOL   shareImageSwitch;//分享图片开关
@property(nonatomic, copy) NSString *shareDesc;//分享图片说明
@property(nonatomic, copy) NSString *bgColor;//图片背景颜色(暂不启用)
@property(nonatomic, strong) CJPayShareImageModel *shareImage;//分享的图片信息
@property(nonatomic, copy) NSString *payDeskTitle;//收银台标题
@property(nonatomic, copy) NSString *amount;//金额
@property(nonatomic, copy) NSString *tradeName;//订单名称

@end


NS_ASSUME_NONNULL_END

