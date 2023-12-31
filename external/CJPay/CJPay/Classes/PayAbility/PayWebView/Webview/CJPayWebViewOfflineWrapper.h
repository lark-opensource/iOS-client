//
//  CJPayWebViewOfflineWrapper.h
//  Pods
//
//  Created by 易培淮 on 2021/5/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWebViewOfflineWrapper : NSObject

+ (instancetype)shared;
- (void)i_registerOffline:(NSString *)appid;

@end

NS_ASSUME_NONNULL_END
