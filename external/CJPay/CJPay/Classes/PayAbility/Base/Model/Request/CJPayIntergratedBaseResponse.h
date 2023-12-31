//
//  CJPayIntergratedBaseResponse.h
//  CJPay
//
//  Created by wangxinhua on 2020/9/9.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIntergratedBaseResponse : JSONModel

@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *errorType;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSString *innerMsg;
@property (nonatomic, copy) NSString *typecnt;
@property (nonatomic, copy) NSString *errorData;
@property (nonatomic, copy) NSString *processStr;
// 请求响应的时间间隔
@property (nonatomic, assign) NSTimeInterval responseDuration;

- (BOOL)isSuccess;

+ (NSDictionary *)basicMapperWith:(NSDictionary *)newDic;

@end

NS_ASSUME_NONNULL_END
