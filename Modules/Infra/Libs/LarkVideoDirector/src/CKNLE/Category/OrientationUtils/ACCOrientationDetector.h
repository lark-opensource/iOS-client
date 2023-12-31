//
//  AWEOrientationDetector.h
//  Pods
//
//  Created by Howie He on 2020/8/10.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCOrientationDetector <NSObject>

/// KVO Supported
@property (nonatomic, readonly) UIDeviceOrientation orientation;

- (void)startDetect;
- (void)stopDetect;

@end

NS_ASSUME_NONNULL_END
