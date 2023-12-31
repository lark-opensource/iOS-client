//
//  CJPayMemAgreementModel.h
//  CJPay
//
//  Created by 尚怀军 on 2020/2/24.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayQuickPayUserAgreement;
@interface CJPayMemAgreementModel : JSONModel

@property (nonatomic, copy) NSString *group; //协议所属组
@property (nonatomic, copy) NSString *name; //协议标题
@property (nonatomic, copy) NSString *url; //协议跳转链接
@property (nonatomic, assign) BOOL isChoose; //标识是否勾选了协议

- (CJPayQuickPayUserAgreement *)toQuickPayUserAgreement;

@end

NS_ASSUME_NONNULL_END
