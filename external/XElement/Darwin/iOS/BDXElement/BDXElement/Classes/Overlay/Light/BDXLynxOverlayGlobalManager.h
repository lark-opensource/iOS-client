//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "BDXLynxOverlayLightContainer.h"


NS_ASSUME_NONNULL_BEGIN

/**
 * x-overlay-ng introduces the conception of `level`, which rearrange all the Overlays from the small level to the large level.
 * BDXLynxOverlayGlobalManager is designed to make it works.
 */
@interface BDXLynxOverlayGlobalManager : NSObject

+ (instancetype)sharedInstance;
+ (NSMutableArray*)getAllVisibleOverlay;


/**
 * Display the overlay according to its level and mode
 * @return the container in the corresponding mode which contains the overlay
 */
- (UIView *)showOverlayView:(UIView *)overlay atLevel:(NSInteger)level withMode:(BDXLynxOverlayLightMode)mode customViewController:(UIViewController *)customViewController;


/**
 * Destory the overlay according to its level and mode
 */
- (void)destoryOverlayView:(UIView *)overlay atLevel:(NSInteger)level withMode:(BDXLynxOverlayLightMode)mode customViewController:(UIViewController *)customViewController;

@end

NS_ASSUME_NONNULL_END
