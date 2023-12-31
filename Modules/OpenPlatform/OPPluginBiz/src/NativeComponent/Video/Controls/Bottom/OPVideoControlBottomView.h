//
//  OPVideoControlBottomView.h
//  OPPluginBiz
//
//  Created by baojianjun on 2022/4/20.
//

#import <UIKit/UIKit.h>
//#import "TMAVideoControlViewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OPVideoControlBottomItemAlign) {
    OPVideoControlBottomItemAlignLeft,
    OPVideoControlBottomItemAlignRight
};

@interface OPVideoControlBottomItem : NSObject

@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) BOOL show;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) OPVideoControlBottomItemAlign alignment;

@end

@protocol OPVideoControlBottomViewDelegate<NSObject>

- (void)tma_playerCancelAutoFadeOutControlView;

@end

@class OPVideoControlViewModel;
@interface OPVideoControlBottomView : UIView

@property (nonatomic, weak) id<OPVideoControlBottomViewDelegate> delegate;

- (instancetype)initWithViewModel:(OPVideoControlViewModel *)viewModel;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)selectStartBtn:(BOOL)selected;
- (void)selectMuteBtn:(BOOL)selected;
- (void)updateTimeLabel:(NSString *)time;
- (void)updateRateBtnText:(CGFloat)value;
- (void)resetControlView;

@end

NS_ASSUME_NONNULL_END
