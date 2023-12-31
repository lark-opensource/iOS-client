//
//  IESAdSplashChannelInterceptor.h
//  Pods
//
//  Created by 陈煜钏 on 2019/12/2.
//

#import <Foundation/Foundation.h>

#import <BDWebKit/IESFalconManager.h>
#import "IESFalconGurdInterceptionDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * _Nonnull(^IESFalconAdSplashGetChannelBlock)(NSURL *requestURL);
 
@interface IESAdSplashChannelInterceptor : NSObject <IESFalconCustomInterceptor>

- (instancetype)initWithGurdAccessKey:(NSString *)gurdAccessKey
                      getChannelBlock:(IESFalconAdSplashGetChannelBlock)getChannelBlock NS_DESIGNATED_INITIALIZER;

- (void)registerInterceptionDelegate:(id<IESFalconGurdInterceptionDelegate>)gurdInterceptionDelegate;

- (void)unregisterInterceptionDelegate:(id<IESFalconGurdInterceptionDelegate>)gurdInterceptionDelegate;

@end

NS_ASSUME_NONNULL_END
