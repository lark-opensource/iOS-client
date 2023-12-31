//
//  LKNativeAppExtensionFinder.h
//  LKNativeAppContainer
//
//  Created by bytedance on 2021/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKNativeAppExtensionConfig : NSObject

@property (nonatomic, readonly) NSString *implName;
@property (nonatomic, readonly) NSString *appId;
@property (nonatomic, readonly) BOOL preLaunch;

- (instancetype)initWithDictionary:(NSDictionary *)params;

@end

@interface LKNativeAppExtensionFinder : NSObject

+ (LKNativeAppExtensionFinder *)shared;

- (LKNativeAppExtensionConfig * _Nullable)getConfigByAppId:(NSString *)appId;

@end

NS_ASSUME_NONNULL_END
