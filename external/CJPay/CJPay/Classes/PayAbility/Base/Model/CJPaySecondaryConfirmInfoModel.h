//
//  CJPaySecondaryConfirmInfoModel.h
//  Pods
//
//  Created by bytedance on 2021/11/15.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySecondaryConfirmInfoModel : JSONModel

//https://www.figma.com/file/2kTn8Wx1bqCad1qK4b6oHu/%E7%9B%B4%E6%92%AD-%C2%B7-%E6%8A%96%E9%9F%B3%E6%94%AF%E4%BB%98?type=design&node-id=6549-14027&t=ARmCYa84QRrUc8as-0
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *tipsCheckbox;
@property (nonatomic, copy) NSString *choicePwdCheckWay;
@property (nonatomic, copy) NSString *nopwdConfirmHidePeriod;
@property (nonatomic, copy) NSString *style;//V1、V2、V3是弹窗样式，V4、V5是半屏样式
@property (nonatomic, copy) NSString *buttonText;
@property (nonatomic, copy) NSString *checkboxSelectDefault;

@property (nonatomic, copy) NSString *standardRecDesc;
@property (nonatomic, copy) NSString *standardShowAmount;

@end

NS_ASSUME_NONNULL_END
