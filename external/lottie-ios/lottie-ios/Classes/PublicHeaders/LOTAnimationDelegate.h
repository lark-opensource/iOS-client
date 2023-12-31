//
//  LOTAnimationDelegate.h
//  lottie-ios
//
//  Created by Lizhen Hu on 2020/11/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSErrorDomain LOTErrorDomain = @"LOTErrorDomain";

static NSString * const LOTResourceURLKey = @"LOTResourceURLKey";

@class UIImage;
@class LOTAnimationView;

typedef void(^LOTResourceCompletionHandler)(UIImage * _Nullable image, NSError * _Nullable error);

@protocol LOTAnimationDelegate <NSObject>

@optional

- (void)animationView:(LOTAnimationView *)animationView fetchResourceWithURL:(NSURL *)url completionHandler:(LOTResourceCompletionHandler)completionHandler;

- (void)animationView:(LOTAnimationView *)animationView didLoadResourcesWithError:(nullable NSError *)error;

- (void)animationViewDidStart:(LOTAnimationView *)animationView;

- (void)animationViewDidStop:(LOTAnimationView *)animationView;

- (void)animationViewDidPause:(LOTAnimationView *)animationView;

- (void)animationView:(LOTAnimationView *)animationView isDisplayingFrame:(float)frame;

@end

NS_ASSUME_NONNULL_END
