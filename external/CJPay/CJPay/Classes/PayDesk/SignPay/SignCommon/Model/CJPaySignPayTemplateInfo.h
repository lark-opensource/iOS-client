//
//  CJPaySignPayTemplateInfo.h
//  CJPay-a399f1d1
//
//  Created by wangxiaohong on 2022/9/15.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySignPayTemplateInfo : JSONModel

@property (nonatomic, copy) NSString *templateId;
@property (nonatomic, copy) NSString *zgMerchantId;
@property (nonatomic, copy) NSString *zgMerchantName;
@property (nonatomic, copy) NSString *zgMerchantAppid;
@property (nonatomic, copy) NSString *serviceName;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *serviceDesc;
@property (nonatomic, copy) NSString *pageTitle;
@property (nonatomic, copy) NSString *buttonDesc;
@property (nonatomic, copy) NSArray *supportPayType;

@end

NS_ASSUME_NONNULL_END
