//
//  CJPayCenterTextFieldContainer.h
//  Pods
//
//  Created by xiuyuanLee on 2020/12/9.
//

#import "CJPayCustomTextFieldContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCenterTextFieldContainer : CJPayCustomTextFieldContainer
- (instancetype)initWithFrame:(CGRect)frame
                textFieldType:(CJPayTextFieldType)textFieldType type:(CJPayContainerStyle)type;
- (void)showBorder:(BOOL)show;
- (void)showBorder:(BOOL)show withColor:(UIColor *)color;
- (void)clearTextWithEndAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
