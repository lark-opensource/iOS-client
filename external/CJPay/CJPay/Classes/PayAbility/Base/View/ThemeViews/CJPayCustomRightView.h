//
//  CJPayCustomRightView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/24.
//  Modified by xiuyuanLee on 2020/10/19
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayButton;
@interface CJPayCustomRightView : UIView

@property (nonatomic,strong) CJPayButton *rightButton;

- (void)setRightButtonImageWithName:(NSString *)imageName;
- (void)setRightButtonCenterOffset:(NSInteger)offset;

@end

NS_ASSUME_NONNULL_END
