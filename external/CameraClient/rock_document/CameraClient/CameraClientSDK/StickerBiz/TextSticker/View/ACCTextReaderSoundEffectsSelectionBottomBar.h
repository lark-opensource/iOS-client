//
//  ACCTextReaderSoundEffectsSelectionBottomBar.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const kACCTextReaderSoundEffectsSelectionBottomBarHeight;

@interface ACCTextReaderSoundEffectsSelectionBottomBar : UIView

@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UILabel *titleLbl;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *saveBtn;

@property (nonatomic, copy) void (^didTapSaveButtonBlock)(void);
@property (nonatomic, copy) void (^didTapCancelButtonBlock)(void);

@end

NS_ASSUME_NONNULL_END
