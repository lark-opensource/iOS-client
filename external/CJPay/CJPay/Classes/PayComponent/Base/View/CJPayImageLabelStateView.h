//
//  CJPayImageLabelStateView.h
//  CJPay
//
//  Created by 王新华 on 2019/1/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayImageLabelStateViewDelegate <NSObject>

- (void)clickBtn:(NSString *)btnName;

@end

@interface CJPayStateShowModel : NSObject

@property (nonatomic, copy) NSString *titleStr;
@property (nonatomic, strong) NSMutableAttributedString *titleAttributedStr;
@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, assign) CGFloat imgDurationTime;
@property (nonatomic, strong) UIColor *iconBackgroundColor;

@end

@interface CJPayImageLabelStateView : UIView

- (instancetype)initWithModel:(CJPayStateShowModel *)model;
- (void)animationForOneKeyPay;

@end

NS_ASSUME_NONNULL_END
