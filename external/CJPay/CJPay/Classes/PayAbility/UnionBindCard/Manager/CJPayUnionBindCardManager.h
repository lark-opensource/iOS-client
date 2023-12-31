//
//  CJPayUnionBindCardManager.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/29.
//

#import <Foundation/Foundation.h>

#import "CJPayUnionBindCardListResponse.h"
#import "CJPayUnionPaySignInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionBindCardHalfAccreditViewController;
@class CJPayUnionCopywritingInfo;
@interface CJPayUnionBindCardManager : NSObject

+ (instancetype)shared;

- (void)openLiveDetectWithCompletion:(void (^)(BOOL))completion;
- (void)openHalfAccreditWithCompletion:(void (^)(BOOL))completion;
- (void)openChooseCardListWithCompletion:(void (^)(BOOL))completion;


@end

NS_ASSUME_NONNULL_END
