//
//  CJPayBaseResponse.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/24.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@interface CJPayBaseResponse : JSONModel

// 返回码和信息
@property (nonatomic, copy) NSString *code; //
@property (nonatomic, copy) NSString *msg;
// 响应状态： 成功 SUCCESS，失败 FAILED，未知 UNKNOWN
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *errorType;
@property (nonatomic, copy) NSString *typeContent;

// 其他信息
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *sign;

// 标记是否来自缓存
@property (nonatomic, assign) BOOL isFromCache;
// 请求响应的时间间隔
@property (nonatomic, assign) NSTimeInterval responseDuration;

- (BOOL)isSuccess;

- (BOOL)isNeedThrottle;

+ (NSMutableDictionary *)basicDict;

@end
