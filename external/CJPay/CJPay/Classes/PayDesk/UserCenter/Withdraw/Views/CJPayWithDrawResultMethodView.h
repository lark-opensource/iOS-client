//
//  BDPayWithDrawResultMethodView.h
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawResultMethodView : UIView
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *contentLabel;

- (void)setImage:(UIImage *)image content:(NSString *)content;
- (void)setImageUrl:(NSString *)imageUrl content:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
