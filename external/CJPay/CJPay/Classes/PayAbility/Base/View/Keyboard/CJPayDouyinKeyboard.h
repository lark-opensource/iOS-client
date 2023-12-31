//
//  AWEIMDouyinNumberKeyboard.h
//  Aweme
//
//  Created by wangxinhua on 2022/11/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayDouyinNumberKeyboardType) {
    CJPayDouyinNumberKeyboardTypeQuantity,
    CJPayDouyinNumberKeyboardTypeMoney,
};

static const CGFloat kKeyBoardButtonMargin = 6.0f;

#define kKeyBoardConfirmBtnHeight 150.0f
#define kKeyBoardConfirmBtnWidth (CJ_SCREEN_WIDTH - 5 * kKeyBoardButtonMargin) / 4
#define kKeyBoardConfirmBtnRightMargin 6.0f
#define kKeyBoardConfirmBtnBottomMargin (CJ_IPhoneX? 38.0f : 4.0f)
#define kKeyboardHeight (CJ_IPhoneX? 248.0f : 214.0f)

@interface CJPayDouyinKeyboard : UIView

@property (nonatomic, assign) CJPayDouyinNumberKeyboardType keyBoardType;
@property (nonatomic, copy) void(^inputStrBlock)(NSString *str);
@property (nonatomic, copy) void(^deleteBlock)(void);
@property (nonatomic, copy) void(^dismissBlock)(void);


@end

NS_ASSUME_NONNULL_END
