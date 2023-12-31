//
//  CJPayServerEventPostRequest.h
//  Pods
//
//  Created by 王新华 on 2021/8/9.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayServerEvent : JSONModel
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSDictionary *extra;
@property (nonatomic, copy) NSString *intergratedMerchantId;

@end

@interface CJPayServerEventPostRequest : CJPayBaseRequest

+ (void)postEvents:(NSArray<CJPayServerEvent *> *)events completion:(void(^)(NSError *error, CJPayBaseResponse *response))completion;

@end

NS_ASSUME_NONNULL_END
