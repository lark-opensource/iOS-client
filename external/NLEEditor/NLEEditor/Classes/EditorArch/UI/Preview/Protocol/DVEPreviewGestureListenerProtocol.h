//
//  DVEPreviewGestureListenerProtocol.h
//  Pods
//
//  Created by pengzhenhuan on 2022/1/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEPreviewManagerProtocol;

@protocol DVEPreviewGestureListenerProtocol <NSObject>

@optional

//移动
- (BOOL)onGesturePan:(UIPanGestureRecognizer *)gesture
  withPreviewManager:(id<DVEPreviewManagerProtocol>)previewManager;

//旋转
- (BOOL)onGestureRotate:(UIRotationGestureRecognizer *)gesture
     withPreviewManager:(id<DVEPreviewManagerProtocol>)previewManager;

//缩放
- (BOOL)onGestureScale:(UIPinchGestureRecognizer *)gesture
    withPreviewManager:(id<DVEPreviewManagerProtocol>)previewManager;

//单击选中
- (BOOL)didSingleTap:(UITapGestureRecognizer *)gesture
  withPreviewManager:(id<DVEPreviewManagerProtocol>)previewManager;

//双击
- (BOOL)didDoubleTap:(UITapGestureRecognizer *)gesture
  withPreviewManager:(id<DVEPreviewManagerProtocol>)previewManager;
    
//长按view
- (BOOL)onGestureLongPress:(UILongPressGestureRecognizer *)gesture
        withPreviewManager:(id<DVEPreviewManagerProtocol>)previewManager;

@end

NS_ASSUME_NONNULL_END
