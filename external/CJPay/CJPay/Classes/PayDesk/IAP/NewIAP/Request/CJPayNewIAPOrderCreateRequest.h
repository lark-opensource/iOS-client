//
//  CJPayNewIAPOrderCreateRequest.h
//  Pods
//
//  Created by 尚怀军 on 2022/3/7.
//

#import "CJPayBaseRequest.h"
#import "CJPayNewIAPOrderCreateResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNewIAPOrderCreateRequest : CJPayBaseRequest

+ (void)startRequest:(NSString *)appid
              params:(NSDictionary *)params
                exts:(NSDictionary *)extParams
          completion:(void(^)(NSError *error, CJPayNewIAPOrderCreateResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
