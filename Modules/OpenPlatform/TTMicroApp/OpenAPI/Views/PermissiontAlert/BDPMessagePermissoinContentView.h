//
//  BDPMessagePermissoinContentView.h
//  Timor
//
//  Created by 刘相鑫 on 2019/6/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPMessagePermissoinContentView : UIView

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *message;

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *messageLabel;

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message  isNewStyle:(BOOL)enableNewStyle;

@end

NS_ASSUME_NONNULL_END
