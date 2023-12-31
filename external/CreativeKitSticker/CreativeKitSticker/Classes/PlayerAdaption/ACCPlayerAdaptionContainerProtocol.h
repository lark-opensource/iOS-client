//
//  ACCPlayerAdaptionContainerProtocol.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPlayerAdaptionContainerProtocol <NSObject>

@property (nonatomic, assign, readonly) CGRect originalFrame;
@property (nonatomic, assign, readonly) CGPoint mediaCenter;
@property (nonatomic, strong, readonly) UIView *playerPreviewView;
@property (nonatomic, strong, readonly) NSValue *playerFrame; // stand for playerFrame when container's frame not equal to player's frame due to masks; nil when no masks; IMPORTANT!!!

@property (nonatomic, strong, readonly) UIView *playerContainerView;

@property (nonatomic, strong, readonly) UIView *overlayView;

- (CGRect)playerRect;

@end

NS_ASSUME_NONNULL_END
