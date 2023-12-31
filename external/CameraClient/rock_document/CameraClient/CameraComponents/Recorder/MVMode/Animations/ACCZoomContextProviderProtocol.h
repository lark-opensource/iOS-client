//
//  ACCZoomContextProviderProtocol.h
//  CameraClient
//
//  Created by long.chen on 2020/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCZoomTransitionTriggerDirection) {
    ACCZoomTransitionTriggerDirectionAny = 0,
    ACCZoomTransitionTriggerDirectionLeft,
    ACCZoomTransitionTriggerDirectionRight,
    ACCZoomTransitionTriggerDirectionUp,
    ACCZoomTransitionTriggerDirectionDown,
};

@protocol ACCZoomContextOutterProviderProtocol <NSObject>

- (UIView *)acc_zoomTransitionStartViewForItemOffset:(NSInteger)itemOffset;

@end


@protocol ACCZoomContextInnerProviderProtocol <NSObject>

@optional
- (UIView *)acc_zoomTransitionEndView;
- (NSInteger)acc_zoomTransitionItemOffset;
- (ACCZoomTransitionTriggerDirection)acc_zoomTransitionAllowedTriggerDirection;

@end

NS_ASSUME_NONNULL_END
