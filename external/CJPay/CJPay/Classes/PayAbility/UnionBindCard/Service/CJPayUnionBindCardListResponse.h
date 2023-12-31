//
//  CJPayUnionBindCardListResponse.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/29.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionCardInfoModel;
@protocol CJPayUnionCardInfoModel;
@class CJPayUnionCopywritingInfo;
@interface CJPayUnionBindCardListResponse : CJPayBaseResponse

@property (nonatomic, copy) NSArray<CJPayUnionCardInfoModel> *cardList;
@property (nonatomic, copy) NSString *hasBindableCard;
@property (nonatomic, strong) CJPayUnionCopywritingInfo *unionCopywritingInfo;

@end

// 无可用绑卡时弹框提示信息
@interface CJPayUnionCopywritingInfo : JSONModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, copy) NSString *displayIcon;

@end

NS_ASSUME_NONNULL_END
