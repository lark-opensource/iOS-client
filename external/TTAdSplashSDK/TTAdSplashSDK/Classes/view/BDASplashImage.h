//
//  BDASplashImage.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/4/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDASplashImage : NSObject
@property (nonatomic, assign) NSInteger currentPlayIndex;
@property (nonatomic, assign, readonly) float frameDuration;
@property (nonatomic, strong, readonly) UIImage *image;

+ (instancetype)createWithImage:(UIImage *)image frameDuration:(float)duration;

@end

NS_ASSUME_NONNULL_END
