//
//  CJPayBindCardController.h
//  Pods
//
//  Created by wangxiaohong on 2021/1/26.
//

#import <Foundation/Foundation.h>

#import "CJPayCardManageModule.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDPayBindCardCompletion)(CJPayBindCardResult type, NSString *errorMsg);

@interface CJPayBindCardController : NSObject

- (void)startBindCardWithParams:(NSDictionary *)params completion:(BDPayBindCardCompletion)completion;

@end

NS_ASSUME_NONNULL_END
