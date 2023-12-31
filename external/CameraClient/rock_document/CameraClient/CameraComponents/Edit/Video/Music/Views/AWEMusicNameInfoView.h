//
//  AWEMusicNameInfoView.h
//  AWEStudio
//
//  Created by Liu Deping on 2019/10/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEMusicNameInfoView : UIView

- (void)configRollingAnimationWithLabelString:(NSString *)musicLabelString;

- (void)addViewTapTarget:(id)target action:(SEL)action;

@property (nonatomic, assign) BOOL isDisableStyle;

@end

NS_ASSUME_NONNULL_END
