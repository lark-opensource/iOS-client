//
//  CJPayVerifySMSInputModule.h
//  Pods
//
//  Created by 张海阳 on 2019/10/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface CJPayVerifySMSInputModule : UIView

@property (nonatomic, assign) NSUInteger textCount;

@property (nonatomic, copy) NSString *bigTitle;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, copy, readonly) NSString *textValue;
@property (nonatomic, copy) NSString *buttonTitle;
@property (nonatomic, copy) void (^buttonAction)(BOOL isEnabled);

@property (nonatomic, strong) UIColor *cursorColor UI_APPEARANCE_SELECTOR;

- (void)setButtonEnable:(BOOL)enable title:(NSString *)title;

- (void)clearText;

@end


@protocol CJPayVerifySMSInputModuleDelegate <NSObject>

- (void)inputModule:(CJPayVerifySMSInputModule *)inputModule completeInputWithText:(NSString *)text;
- (void)inputModule:(CJPayVerifySMSInputModule *)inputModule textDidChange:(NSString *)text;

@end


@interface CJPayVerifySMSInputModule ()

@property (nonatomic, weak) id<CJPayVerifySMSInputModuleDelegate> delegate;

@end


NS_ASSUME_NONNULL_END
