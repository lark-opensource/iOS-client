//
//  CJPayNativeBindCardManager.h
//  Aweme
//
//  Created by 陈博成 on 2023/5/6.
//

#import <Foundation/Foundation.h>
#import "CJPayCardManageModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNativeBindCardManager : NSObject

+ (instancetype)shared;

- (void)enterQuickBindCardWithCompletionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock;

@end

NS_ASSUME_NONNULL_END
