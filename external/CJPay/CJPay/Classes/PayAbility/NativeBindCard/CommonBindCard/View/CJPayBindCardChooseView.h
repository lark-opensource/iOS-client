//
//  CJPayBindCardChooseView.h
//  CJPay
//
//  Created by 徐天喜 on 2022/08/05
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardChooseView : UIView

@property (nonatomic, assign) BOOL isClickStyle;
@property (nonatomic, strong) UIImageView *rightImageView;

- (void)updateWithMainStr:(NSString *)mainStr
                   subStr:(NSString *)subStr;

@end

NS_ASSUME_NONNULL_END
