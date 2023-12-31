//
//  BDXLynxLottieView.h
//  BDXElement
//
//  Created by li keliang on 2020/3/17.
//

#import <Lynx/LynxUI.h>
#if __has_include(<Lottie/Lottie.h>)
#define OCLottieEnable 1
#import <Lottie/Lottie.h>
#else
@import BDXBridgeSwiftLottie;
#endif


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXLottieErrorCode) {
    BDXLottieErrorCodeInvalidData = 1,
    // Reserved 2
    // Reserved 3
    BDXLottieErrorCodeLocalResourcesNotFound = 4,
};

#if OCLottieEnable
@interface BDXLynxLottieView : LynxUI<LOTAnimationView *>
#else
@interface BDXLynxLottieView : LynxUI<UIView<BridgeAnimationViewProtocol> *>
#endif


@end

NS_ASSUME_NONNULL_END
