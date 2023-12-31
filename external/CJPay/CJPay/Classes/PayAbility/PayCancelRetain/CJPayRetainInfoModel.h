//
//  CJPayRetainInfoModel.h
//  Pods
//
//  Created by chenbocheng on 2021/8/11.
//

#import <Foundation/Foundation.h>
#import "CJPayBDRetainInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayTrackerProtocol;
@class CJPayRetainMsgModel;


@interface CJPayRetainInfoModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *topButtonText;
@property (nonatomic, copy) NSString *bottomButtonText;
@property (nonatomic, assign) CJPayRetainVoucherType voucherType;
@property (nonatomic, strong) UIColor *titleColor;
// 弹窗主内容，CJPayRetainVoucherTypeV1使用voucherContent，CJPayRetainVoucherTypeV2使用retainMsgModels
@property (nonatomic, copy) NSString *voucherContent;
@property (nonatomic, copy) NSArray<CJPayRetainMsgModel *> *retainMsgModels;

@property (nonatomic, copy) void(^topButtonBlock)(void);
@property (nonatomic, copy) void(^closeCompletionBlock)(void);
@property (nonatomic, copy) void(^bottomButtonBlock)(void);

// 埋点
@property (nonatomic, copy) NSString *outPutActivityLabelForTrack;

- (BOOL)hasDiscount;
- (void)trackRetainPopUpWithEvent:(NSString *)event trackDelegate:(id<CJPayTrackerProtocol>)trackDelegate extraParam:(NSDictionary *)extraParam;

@end

NS_ASSUME_NONNULL_END
