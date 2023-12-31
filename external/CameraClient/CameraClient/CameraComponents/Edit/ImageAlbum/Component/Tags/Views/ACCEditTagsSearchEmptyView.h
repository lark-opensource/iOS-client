//
//  ACCEditTagsSearchEmptyView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/8.
//

#import <UIKit/UIKit.h>
@class ACCEditTagsSearchEmptyView;

@protocol ACCEditTagsSearchEmptyViewDelegate <NSObject>

- (void)didTapOnEmptView:(ACCEditTagsSearchEmptyView * _Nonnull)emptyView;
- (void)didTapOnActionButtonInEmptyView:(ACCEditTagsSearchEmptyView * _Nonnull)emptyView;

@end

@interface ACCEditTagsSearchEmptyView : UIView

@property (nonatomic, weak, nullable) id<ACCEditTagsSearchEmptyViewDelegate> delegate;

- (void)updateWithText:(NSString * _Nullable)text;

@end
