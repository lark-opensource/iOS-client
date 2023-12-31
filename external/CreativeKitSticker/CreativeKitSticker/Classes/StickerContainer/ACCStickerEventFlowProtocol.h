//
//  ACCStickerEventFlowProtocol.h
//  CreativeKitSticker-Pods-Aweme
//
//  Created by yangguocheng on 2020/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerEventFlowProtocol <NSObject>

- (void)editorSticker:(UIView * _Nullable)editView receivedTapGesture:(UITapGestureRecognizer *)gesture;

- (void)editorSticker:(UIView * _Nullable)editView receivedPanGesture:(UIPanGestureRecognizer *)gesture;

- (void)editorSticker:(UIView * _Nullable)editView receivedPinchGesture:(UIPinchGestureRecognizer *)gesture;

- (void)editorSticker:(UIView * _Nullable)editView receivedRotationGesture:(UIRotationGestureRecognizer *)gesture;

// this method must be invoke before Gesture be Recognized in Sticker System
- (void)beforeGestureBeRecognizerInSticker:(UIGestureRecognizer *)gesture;

- (nullable UIView *)targetViewFor:(UIGestureRecognizer *)gesture;

- (BOOL)endEditIfNeeded:(UIGestureRecognizer *)gesture onTargetChange:(UIView *)changeTo;

@end

NS_ASSUME_NONNULL_END
