//
//  TTVideoEnginePreloader+Private.h
//  TTVideoEngine
//
//  Created by 黄清 on 2020/4/20.
//


#import "TTVideoEnginePreloader.h"


NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEnginePreloader (Private)

+ (void)notifyPreload:(nullable TTVideoEngine *)engine info:(NSDictionary *)info;
+ (void)notifyPreloadCancel:(nullable TTVideoEngine *)engine info:(NSDictionary *)info;

+ (NSMutableSet *)classSet;

+ (BOOL)hasRegistClass;

@end

NS_ASSUME_NONNULL_END
