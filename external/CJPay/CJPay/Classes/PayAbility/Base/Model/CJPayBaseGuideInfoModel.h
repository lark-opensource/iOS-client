//
//  CJPayBaseGuideInfoModel.h
//  Pods
//
//  Created by mengxin on 2021/5/23.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayMemAgreementModel;
@interface CJPayBaseGuideInfoModel : JSONModel

@property (nonatomic, assign) BOOL needGuide; // 是否需要展示免密引导
@property (nonatomic, copy) NSString *title; // 支付后免密提额引导主标题
@property (nonatomic, copy) NSDictionary *protocolGroupNames; // 协议组文案
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *protocoList; // 协议组详细信息（跳转链接、协议页面标题等）
@property (nonatomic, copy) NSString *buttonText; // 确认按钮文案
@property (nonatomic, copy) NSString *guideMessage; // （协议前的）引导文案
@property (nonatomic, copy) NSString *voucherAmount; // 支付后引导展示营销文案
@property (nonatomic, assign) BOOL isButtonFlick; // 支付后营销引导时是否在确认按钮展示flickIcon

+ (NSMutableDictionary *)basicDict;

@end

NS_ASSUME_NONNULL_END
