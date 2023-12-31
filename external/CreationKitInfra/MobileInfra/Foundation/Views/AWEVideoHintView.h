//
//  AWEVideoHintView.h
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by hanxu on 2019/5/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoHintView : UIView

@property (nonatomic, strong, readonly) UILabel *topLabel;
@property (nonatomic, strong, readonly) UILabel *bottomLabel;

- (void)updateTopText:(NSString *)topText bottomText:(NSString *)bottomText;

@end

NS_ASSUME_NONNULL_END
