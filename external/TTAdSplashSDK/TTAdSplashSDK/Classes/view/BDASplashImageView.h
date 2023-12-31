//
//  BDASplashImageView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/4/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDASplashImagePlayCompletion)(void);

@interface BDASplashImageView : UIImageView
@property (nonatomic, assign) BOOL isRepeat;
@property (nonatomic, assign, readonly) float currentTime;
@property (nonatomic, assign, readonly) float duration;

@property (nonatomic, copy) BDASplashImagePlayCompletion completionHandler;

- (void)setImageWithData:(NSData *)data;

- (BOOL)isAnimatedImage;

@end

NS_ASSUME_NONNULL_END
