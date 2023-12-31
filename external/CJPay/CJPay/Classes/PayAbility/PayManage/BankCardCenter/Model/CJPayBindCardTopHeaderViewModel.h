//
//  CJPayBindCardTopHeaderViewModel.h
//  Pods
//
//  Created by 孟源 on 2022/8/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayVoucherListModel;

@interface CJPayBindCardTopHeaderViewModel : NSObject
// 营销
@property (nonatomic, copy) NSString *voucherMsg;
@property (nonatomic, strong) CJPayVoucherListModel *voucherList;

// 安全感文案
@property (nonatomic, copy) NSString *displayIcon;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, assign) BOOL forceShowTopSafe;

//主标题信息
@property (nonatomic, copy) NSString *preTitle;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *bankIcon;
@property (nonatomic, copy) NSString *orderAmount;

- (NSMutableAttributedString *)getAttributedStringWithCompletion:(void (^)(NSMutableAttributedString * _Nullable attributedStr))completion;
// 获取标题中金额的字体样式
- (NSMutableAttributedString *)getAmountAttributedString:(NSString *)amount;

@end

NS_ASSUME_NONNULL_END
