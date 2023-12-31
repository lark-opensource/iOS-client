//
//  OKStartUpSchemeHandler.h
//  OKStartUp
//
//  Created by bob on 2020/1/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OKSchemeHandler <NSObject>

/*! @abstract 处理scheme
 @param URL scheme的完整URL
 @param options 透传参数
 @result 返回YES，表示能处理了该URL，NO表示不能处理
*/
- (BOOL)canHandleURL:(NSURL *)URL options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

/*! @abstract 处理scheme
 @param URL scheme的完整URL，透传参数
 @param application 初始化SDK的AppID
 @param scene 适配iOS 13的参数，透传参数, UIScene,暂时都是传nil
 @param options 透传参数
 @result 返回YES，表示已经处理了该URL，NO表示没有处理
*/
- (BOOL)handleURL:(NSURL *)URL
      application:(UIApplication *)application
            scene:(nullable id)scene
          options:(nullable NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

@end

@interface OKStartUpSchemeHandler : NSObject<OKSchemeHandler>

+ (instancetype)sharedHandler;

- (void)registerHandler:(id<OKSchemeHandler>)handler;
- (void)unregisterHandler:(id<OKSchemeHandler>)handler;

@end

NS_ASSUME_NONNULL_END
