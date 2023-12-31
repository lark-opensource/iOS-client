//
//  BDPXScreenNavigationBar.h
//  TTMicroApp
//
//  Created by qianhongqiang on 2022/8/28.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, BDPDirectionPanGestureRecognizerDirection) {
    kBDPDirectionPanGestureRecognizerDirectionUnknown       = 0,
    kBDPDirectionPanGestureRecognizerDirectionLTR           = 1 << 0, //➡️ Left to right
    kBDPDirectionPanGestureRecognizerDirectionRTL           = 1 << 1, //⬅️ Right to left
    kBDPDirectionPanGestureRecognizerDirectionTTB           = 1 << 2, //⬇️ Top to bottom
    kBDPDirectionPanGestureRecognizerDirectionBTT           = 1 << 3, //⬆️ Bottom to top
    kBDPDirectionPanGestureRecognizerDirectionHorizontal    = kBDPDirectionPanGestureRecognizerDirectionLTR | kBDPDirectionPanGestureRecognizerDirectionRTL,
    kBDPDirectionPanGestureRecognizerDirectionVertical      = kBDPDirectionPanGestureRecognizerDirectionTTB | kBDPDirectionPanGestureRecognizerDirectionBTT
};

typedef NS_ENUM(NSUInteger, BDPDirectionPanGestureRecognizerMode) {
    kBDPDirectionPanGestureRecognizerModeIgnore = 0,        // ❌ No response
    kBDPDirectionPanGestureRecognizerModeFullScreen,        // 📱 Fullscreen reponse touch event
    kBDPDirectionPanGestureRecognizerModeScreenEdge,        // 👆 Screen edge reponse touch event
};

@interface BDPDirectionPanGestureRecognizer : UIPanGestureRecognizer

@property(nonatomic, assign) BDPDirectionPanGestureRecognizerMode mode;
@property(nonatomic, assign) BDPDirectionPanGestureRecognizerDirection allowDirection;

@end
