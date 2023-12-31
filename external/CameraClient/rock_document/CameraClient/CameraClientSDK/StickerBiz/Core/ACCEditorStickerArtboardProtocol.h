//
//  ACCEditorStickerArtboardProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by aloes on 2020/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 投票>视频评论>(poi&文字贴纸)>商业化贴纸
typedef NS_ENUM(NSInteger, AWEStickerHierarchy) {
    AWEStickerHierarchyCommercialSticker = 10001,
    AWEStickerHierarchyPOISticker = 20001,
    AWEStickerHierarchyPollSticker = 50001,
};

@protocol AWEEditorStickerGestureProtocol <NSObject>

- (void)editorSticker:(UIView * _Nullable)editView receivedTapGesture:(UITapGestureRecognizer *)gesture;

- (void)editorSticker:(UIView * _Nullable)editView receivedPanGesture:(UIPanGestureRecognizer *)gesture;

- (void)editorSticker:(UIView * _Nullable)editView receivedPinchGesture:(UIPinchGestureRecognizer *)gesture;

- (void)editorSticker:(UIView * _Nullable)editView receivedRotationGesture:(UIRotationGestureRecognizer *)gesture;

- (void)editorStickerGestureStarted;

@end

@protocol ACCEditorStickerArtboardProtocol <AWEEditorStickerGestureProtocol>
- (UIView *)targetViewFor:(UIGestureRecognizer *)gesture;
- (BOOL)isChildView:(UIView *)targetView;
- (UIView *)operatingView;
@property (nonatomic, assign) AWEStickerHierarchy hierarchy;

@optional
- (BOOL)endEditIfNeeded:(UIGestureRecognizer *)gesture onTargetChange:(UIView *)changeTo;
@end


NS_ASSUME_NONNULL_END
