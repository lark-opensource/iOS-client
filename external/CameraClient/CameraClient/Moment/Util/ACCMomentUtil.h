//
//  ACCMomentUtil.h
//  Pods
//
//  Created by Pinka on 2020/6/8.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentUtil : NSObject

+ (NSUInteger)degressFromAsset:(AVAsset *)asset;

+ (NSUInteger)degressFromImage:(UIImage *)image;

+ (NSUInteger)aiOrientationFromDegress:(NSUInteger)degress;

@end

NS_ASSUME_NONNULL_END
