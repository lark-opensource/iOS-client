//
//  CJPayNewIAPOrderCreateModel.m
//  CJPay
//
//  Created by 尚怀军 on 2022/2/22.
//

#import "CJPayNewIAPOrderCreateModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayIAPResultEnumHeader.h"
#import "CJIAPProduct.h"
#import "CJPayNewIAPTransactionInfoModel.h"

@implementation CJPayNewIAPOrderCreateModel

- (instancetype)initWith:(NSString *)fullOrderID {
    if (self = [super init]) {
        if (!fullOrderID || ![fullOrderID hasPrefix:CJPayOrderPrefix]) {
            return self;
        }
        
        NSString *trueOrderID = [fullOrderID substringFromIndex:CJPayOrderPrefix.length];
        NSArray *contents = [trueOrderID componentsSeparatedByString:@"|"];
        if (contents.count < 5) {
            return self;
        }
        
        _uid  = contents[0];
        _merchantId = contents[1];
        _appId = contents[2];
        _tradeNo = contents[3];
        _outTradeNo = contents[4];
    }
    return self;
}

- (BOOL)applicationUsernameUseEncryptUid {
    return self.uidEncrypt && [self.uidEncrypt isEqualToString:@"1"];
}

- (NSString *)customApplicationUsername {
    if ([self applicationUsernameUseEncryptUid]) {
        // 使用uid的md5值作为appusername
        NSString *md5Uid = [self.uid cj_md5String];
        return [NSString stringWithFormat:@"%@%@", CJPayApplicationUserNamePrefix, md5Uid];
    } else {
        // 拼接5个核心参数作为appusername
        return [NSString stringWithFormat:@"%@%@", CJPayOrderPrefix, [self fullOrderID]];
    }
}

- (NSString *)fullOrderID {
    if (![self isValid]) {
        return @"";
    }
    NSMutableString *fullOrderStr = [NSMutableString new];
    [fullOrderStr appendString:_uid];
    [fullOrderStr appendString:@"|"];
    [fullOrderStr appendString:_merchantId];
    [fullOrderStr appendString:@"|"];
    [fullOrderStr appendString:_appId];
    [fullOrderStr appendString:@"|"];
    [fullOrderStr appendString:_tradeNo];
    [fullOrderStr appendString:@"|"];
    [fullOrderStr appendString:_outTradeNo];
    return [fullOrderStr copy];
}

- (BOOL)isValid {
    return _uid && _merchantId && _appId && _tradeNo;
}

- (CJIAPProduct *)toCJIAPProductModel {
    CJIAPProduct *productModel = [CJIAPProduct new];
    productModel.merchantId = self.merchantId;
    productModel.tradeNo = self.tradeNo;
    productModel.outOrderNo = self.outTradeNo;
    
    productModel.productID = CJString(self.transactionModel.productID);
    productModel.receipt = CJString(self.transactionModel.receipt);
    productModel.transactionID = CJString(self.transactionModel.transactionID);
    productModel.originalTransactionID = CJString(self.transactionModel.originalTransactionID);
    productModel.transactionDate =  CJString(self.transactionModel.transactionDate);
    productModel.originalTransactionDate =  CJString(self.transactionModel.originalTransactionDate);
    productModel.iapType = self.iapType;
    
    return productModel;
}

@end
