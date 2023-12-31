//
//  AWEWebImageTransformProtocol.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEWebImageTransformProtocol <NSObject>

@required

- (nonnull NSString *)appendingStringForCacheKey;

- (nullable UIImage *)transformImageBeforeStoreWithImage:(nullable UIImage *)image;

@optional

- (nullable UIImage *)transformImageAfterStoreWithImage:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
