//
//  BDXPickerColumnView.h
//  BDXElement-Pods-Aweme
//
//  Created by 林茂森 on 2020/8/11.
//

#import <UIKit/UIKit.h>
#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN



@class BDXPickerColumnView;

@protocol BDXPickerColumnViewDelegate <NSObject>

- (void)onPickerColumnChangedWithResult:(NSDictionary *)res;

@end


@interface BDXPickerColumnView : UIView

@property (nonatomic, strong) NSArray *columnValue;
@property (nonatomic, copy) NSString *key;
@property (nonatomic) NSInteger index;

@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic, copy) UIColor *fontColor;
@property (nonatomic) UIFontWeight fontWeight;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic, copy) UIColor *borderColor;

@property (nonatomic, strong) UIPickerView *pickerView;

@property (nonatomic, weak) id<BDXPickerColumnViewDelegate> delegate;

@property (nonatomic, assign) BOOL needUpdate;

- (void)reloadPickerFrame;

@end

@interface BDXUIPickerColumnView : LynxUI<BDXPickerColumnView *>



@end



NS_ASSUME_NONNULL_END
