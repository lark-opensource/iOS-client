//
//  ACCAECModelManager.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/3/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCAECModelManager : NSObject

+ (void)downloadAECModel;
+ (void)downloadDAModel;

+ (nullable NSString *)AECModelPath;
+ (nullable NSString *)DAModelPath;

@end

NS_ASSUME_NONNULL_END
