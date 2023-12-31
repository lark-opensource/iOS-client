//
//  CJPayBindCardContainerView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardContainerView : UIView

@property (nonatomic,assign) BOOL isClickStyle;
@property (nonatomic,strong) UIImageView *rightImageView;

- (void)updateWithMainStr:(NSString *)mainStr
                   subStr:(NSString *)subStr;

@end

NS_ASSUME_NONNULL_END
