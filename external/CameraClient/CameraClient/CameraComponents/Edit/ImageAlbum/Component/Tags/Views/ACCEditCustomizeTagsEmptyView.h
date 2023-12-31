//
//  ACCEditCustomizeTagsEmptyView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/8.
//

#import <UIKit/UIKit.h>
@class ACCEditCustomizeTagsEmptyView;
@protocol ACCEditCustomizeTagsEmptyViewDelegate <NSObject>

- (void)didTapOnActionButtonInEmptyView:(ACCEditCustomizeTagsEmptyView * _Nonnull)emptyView;

@end

@interface ACCEditCustomizeTagsEmptyView : UIView

@property (nonatomic, weak, nullable) id<ACCEditCustomizeTagsEmptyViewDelegate> delegate;

+ (UIButton *)generateNewTagActionButtonWithHeight:(CGFloat)actionButtonHeight;

@end
