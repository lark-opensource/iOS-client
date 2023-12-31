//
// Created by 张海阳 on 2019/11/4.
//

#import <Foundation/Foundation.h>
#import "CJPaySafeKeyboard.h"
#import "CJPayEnumUtil.h"

@class CJPaySafeKeyboardStyleConfigModel;


@interface CJPayFixKeyboardView : UIView

@property (nonatomic, strong, readonly) CJPaySafeKeyboard *safeKeyboard;
@property (nonatomic, strong) CJPayStyleButton *completeButton;
@property (nonatomic, strong) UIView *bottomSafeAreaView;
@property (nonatomic, assign) BOOL notShowSafeguard;//是否展示键盘安全险（新样式），默认展示

- (instancetype)initWithSafeGuardIconUrl:(NSString *)url;
- (instancetype)initWithFrameForDenoise:(CGRect)frame;

- (UIView *)snapshot;

@end
