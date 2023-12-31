//
//  BDXPickerView.h
//  BDXElement-Pods-Aweme
//
//  Created by 林茂森 on 2020/8/11.
//

#import <UIKit/UIKit.h>
#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXPickerView : UIView

@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic, copy) UIColor *fontColor;
@property (nonatomic) UIFontWeight fontWeight;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic, copy) UIColor *borderColor;


@end

@interface BDXUIPickerView : LynxUI<BDXPickerView *>

@end

NS_ASSUME_NONNULL_END
