//
//  BDLynxKitModule.h
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
#define BDLynxGeckoEnable 1
#else
#define BDLynxGeckoEnable 0
#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDLComponentInternalProtocol <NSObject>
@required
/**
 *向lynx view注册自定义组件，返回一个实现注册功能的block。仅Component子库使用。
 */
- (void (^)(void))registCustomUIComponent;

@end

@interface BDLynxKitModule : NSObject

+ (void)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

@end

NS_ASSUME_NONNULL_END
