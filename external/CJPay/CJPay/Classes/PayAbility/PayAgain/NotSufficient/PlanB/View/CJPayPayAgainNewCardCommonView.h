//
//  CJPayPayAgainNewCardCommonView.h
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayNotSufficientNewCardCommonViewType) {
    CJPayNotSufficientNewCardCommonViewTypeNormal,
    CJPayNotSufficientNewCardCommonViewTypeCompact //图标组紧凑布局
};

@class CJPayHintInfo;
@interface CJPayPayAgainNewCardCommonView : UIView

- (instancetype)initWithType:(CJPayNotSufficientNewCardCommonViewType)type;
- (void)refreshWithHintInfo:(CJPayHintInfo *)hintInfo;

@end

NS_ASSUME_NONNULL_END
