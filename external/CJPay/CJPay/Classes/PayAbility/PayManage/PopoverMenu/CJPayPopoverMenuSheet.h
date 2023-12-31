//
//  CJPayPopoverMenuSheet.h
//  Pods
//
//  Created by 易培淮 on 2021/3/17.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class CJPayPopoverMenuSheet;
typedef void (^CJPayPopoverMenuModelBlock)(CJPayPopoverMenuSheet *menuSheet, NSInteger buttonIndex);

@interface CJPayPopoverMenuModel : NSObject

@property (nonatomic,   copy) NSString *title;
@property (nonatomic,   copy) CJPayPopoverMenuModelBlock block;
@property (nonatomic, assign) NSTextAlignment titleTextAlignment;
@property (nonatomic, assign) BOOL disable;

+ (instancetype)actionWithTitle:(NSString *)title titleTextAlignment:(NSTextAlignment)titleTextAlignment block:(CJPayPopoverMenuModelBlock)block;

@end

@interface CJPayPopoverMenuSheet : UITableViewController

@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, assign) CGFloat width;

- (void)addButtonWithModel:(CJPayPopoverMenuModel *)model;

- (void)showFromView:(UIView *)view
              atRect:(CGRect)rect
      arrowDirection:(UIPopoverArrowDirection)direction;

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
