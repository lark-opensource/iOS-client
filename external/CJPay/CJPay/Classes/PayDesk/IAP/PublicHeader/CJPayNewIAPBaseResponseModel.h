//
//  CJPayNewIAPBaseResponse.h
//  CJPay
//
//  Created by 尚怀军 on 2022/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNewIAPBaseResponseModel : NSObject

@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSString *status;

- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
