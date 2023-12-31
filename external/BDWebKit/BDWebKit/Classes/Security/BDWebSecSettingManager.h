//
//  BDWebSecSettingManager.h
//  BDWebKit-Pods-Aweme
//
//  Created by huangzhongwei on 2021/4/16.
//

#import <Foundation/Foundation.h>

@protocol BDWebSecSettingDelegate <NSObject>

@optional
+(BOOL)bdForceHttpsRequest;
+(BOOL)shouldForceHttpsForURL:(NSString*)url;
@end

NS_ASSUME_NONNULL_BEGIN


@interface BDWebSecSettingManager : NSObject<BDWebSecSettingDelegate>

@property (strong, nonatomic, class) id<BDWebSecSettingDelegate> settingsDelegate;

@end

NS_ASSUME_NONNULL_END
