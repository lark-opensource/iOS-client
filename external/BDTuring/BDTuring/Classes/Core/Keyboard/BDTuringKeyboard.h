//
//  BDTuringKeyboard.h
//  BDTuring
//
//  Created by bob on 2019/12/17.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDTuringKeyboardDelegate <NSObject>

@optional

- (void)onKeyboardWillShow:(CGFloat)keyboardTop;
- (void)onKeyboardWillHide:(CGFloat)keyboardTop;

@end

@interface BDTuringKeyboard : NSObject

@property (nonatomic, assign) CGFloat keyboardTop;
@property (nonatomic, assign) BOOL keyboardIsShow;
@property (nonatomic, weak, nullable) id<BDTuringKeyboardDelegate> delegate;

+ (instancetype)sharedKeyboard;

@end

NS_ASSUME_NONNULL_END
