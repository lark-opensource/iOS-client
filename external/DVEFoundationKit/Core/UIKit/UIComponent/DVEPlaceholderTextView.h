//
//  DVEPlaceholderTextView.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/7/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEPlaceholderTextViewDelegate <NSObject>

@optional

//改变光标frame
- (CGRect)caretRectWithOriginRect:(CGRect)rect;

@end


@interface DVEPlaceholderTextView : UITextView

@property (nonatomic, weak) id<DVEPlaceholderTextViewDelegate> textViewDelegate;

/** 占位文字 */
@property (nonatomic, copy) NSString *placeholder;
/** 占位文字颜色 */
@property (nonatomic, strong) UIColor *placeholderColor;

@end

NS_ASSUME_NONNULL_END
