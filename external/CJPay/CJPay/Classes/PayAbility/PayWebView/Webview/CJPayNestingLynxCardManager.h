//
//  CJPayNestingLynxCardManager.h
//  Aweme
//
//  Created by ByteDance on 2023/5/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNestingLynxCardManager : NSObject

+ (instancetype)defaultService;

- (void)openSchemeByNtvVC:(NSString *)scheme fromVC:(nonnull UIViewController *)fromVC withInfo:(nonnull NSDictionary *)sdkInfo completion:(void(^)(BOOL isOpenSuccess, NSDictionary * ext))completion;

@end

NS_ASSUME_NONNULL_END
