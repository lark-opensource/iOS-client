//
//  BDXLynxLottieView_Deprecated.h
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

#if OCLottieEnable
@interface BDXLynxLottieView_Deprecated : LynxUI<LOTAnimationView *>
#else
@interface BDXLynxLottieView_Deprecated : LynxUI<UIView<BridgeAnimationViewProtocol> *>
#endif


@end

NS_ASSUME_NONNULL_END
