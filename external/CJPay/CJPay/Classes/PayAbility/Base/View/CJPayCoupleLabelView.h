//
//  CJPayCoupleLabelView.h
//  Pods
//
//  Created by 王新华 on 2021/8/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCoupleLabelView : UIView

@property (nonatomic, strong) UIFont *font;

- (void)updateCoupleLabelContents:(NSArray<NSString *> *)titles;
- (void)updateCoupleLableForSignStatus;

@end

NS_ASSUME_NONNULL_END
