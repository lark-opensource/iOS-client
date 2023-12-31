//
//  ACCEditTagsPickerViewController.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCPanelViewController.h>
#import "ACCEditTagsDefine.h"
#import "AWEInteractionEditTagStickerModel.h"

FOUNDATION_EXPORT void * const ACCEditTagsPickerContext;

@class ACCEditTagsPickerViewController;
@protocol ACCEditTagsPickerViewControllerDelegate<NSObject>
- (void)tagsPicker:(ACCEditTagsPickerViewController * _Nonnull)tagsPicker
      didSelectTag:(AWEInteractionEditTagStickerModel * _Nonnull)tag
       originalTag:(AWEInteractionEditTagStickerModel * _Nullable)originalTag;

- (void)tagsPicker:(ACCEditTagsPickerViewController * _Nonnull)tagsPicker didPanWithRatio:(CGFloat)offset finished:(BOOL)finished dismiss:(BOOL)dismiss;
- (void)tagsPickerDidTapTopBar:(ACCEditTagsPickerViewController * _Nonnull)tagsPicker;
@end

@interface ACCEditTagsPickerViewController : UIViewController<ACCPanelViewProtocol>
@property (nonatomic, weak, nullable) id<ACCEditTagsPickerViewControllerDelegate> delegate;
@property (nonatomic, strong, nullable) AWEInteractionEditTagStickerModel *originalTag;
@property (nonatomic, copy, nullable) NSDictionary *baseTrackerParams;
- (NSTimeInterval)animationDuration;
- (void)resetPanel;
@end
