//
//  CJPayResultPageGuideInfoModel.h
//  Pods
//
//  Created by 利国卿 on 2021/12/8.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CJPayBaseGuideInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayResultPageGuideInfoModel : CJPayBaseGuideInfoModel

/*引导类型
 bio_guide：支付后生物开通引导
 nopwd_guide：支付后免密开通引导
 upgrade：支付后免密提额引导
 */
@property (nonatomic, copy) NSString *guideType;
@property (nonatomic, copy) NSString *confirmBtnDesc;   //确认按钮文案
@property (nonatomic, copy) NSString *cancelBtnDesc;
@property (nonatomic, copy) NSString *cancelBtnLocation;    //取消按钮的位置
@property (nonatomic, copy) NSString *headerDesc;   //导航栏标题
@property (nonatomic, copy) NSString *subTitle; //引导文案子标题
@property (nonatomic, copy) NSString *pictureUrl;   //插图链接
@property (nonatomic, copy) NSString *bioType;  //生物识别引导类型：指纹、面容
@property (nonatomic, copy) NSString *afterOpenDesc;    //开通后提示文案
@property (nonatomic, assign) NSInteger quota; //免密额度，埋点用
@property (nonatomic, copy) NSString *subTitleIconUrl;
@property (nonatomic, copy) NSString *voucherDisplayText;
@property (nonatomic, copy) NSString *subTitleColor;
@property (nonatomic, copy) NSString *guideShowStyle; // 引导的样式
@property (nonatomic, copy) NSString *bubbleText; // 气泡文案
@property (nonatomic, copy) NSString *headerPicUrl;

- (BOOL)isNewGuideShowStyle; // 新样式，但不包括老年版
- (BOOL)isNewGuideShowStyleForOldPeople; // 新样式，且是老年版

@end

NS_ASSUME_NONNULL_END
