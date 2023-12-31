//
//  CJPayQuickPayUserAgreement.h
//  CJPay
//
//  Created by 王新华 on 11/5/19.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayQuickPayUserAgreement : JSONModel

@property (nonatomic, copy) NSString *contentURL;//协议url
@property (nonatomic, assign) BOOL defaultChoose;//是否默认选择
@property (nonatomic, copy) NSString *title;//标题

@end

NS_ASSUME_NONNULL_END
