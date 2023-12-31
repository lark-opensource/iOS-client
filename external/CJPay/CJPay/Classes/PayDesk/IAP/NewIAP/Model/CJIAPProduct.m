//
//  CJIAPProduct.m
//  Pods
//
//  Created by 尚怀军 on 2022/3/7.
//

#import "CJIAPProduct.h"
#import "CJPaySDKMacro.h"

@implementation CJIAPProduct

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"tradeNo": @"tradeNo",
                @"receipt": @"receipt",
                @"productID": @"productID",
                @"transactionID": @"transactionID",
                @"originalTransactionID": @"originalTransactionID",
                @"otherVerifyParams": @"otherVerifyParams",
                @"createTime": @"createTime",
                @"originalTransactionDate": @"originalTransactionDate",
                @"transactionDate": @"transactionDate"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName
{
    if ([propertyName isEqualToString:@"verifyInForeground"]) {
        return YES;
    }
    return NO;
}

- (BOOL)isValid {
    return _receipt.length > 0 || _tradeNo.length > 0;
}

- (BOOL)receiptIsValid {
    return _receipt.length > 0;
}

- (BOOL)isRestoreProduct {
    return [[self.otherVerifyParams cj_stringValueForKey:@"fe_iap_status"] isEqualToString:@"RESTORE"];
}

@end
