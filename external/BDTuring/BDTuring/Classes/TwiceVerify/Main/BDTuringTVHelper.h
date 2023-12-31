//
//  BDTuringTVHelper.h
//  BDTuring-BDTuringResource
//
//  Created by yanming.sysu on 2020/10/29.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringTVHelper : NSObject

+ (UIViewController *)getVisibleTopViewController;

+ (BOOL)isIphoneX;

+ (CGFloat)iphoneXBottomHeight;

@end

@interface NSURL (BDTuringURLUtils)

- (NSURL *)bdturing_URLByMergingQueries:(NSDictionary<NSString *,NSString *> *)queries;

@end

@interface NSString(BDTuringAddition)

- (NSString *)bdturing_URLStringByAppendQueryItems:(NSDictionary *)items;

@end

NS_ASSUME_NONNULL_END
