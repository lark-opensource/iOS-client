//
//  CJPayStyleCheckMark.h
//  CJPay
//
//  Created by liyu on 2019/10/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayStyleCheckMark : UIImageView

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL enable;

- (instancetype)initWithDiameter:(CGFloat)diameter;

@end

NS_ASSUME_NONNULL_END
