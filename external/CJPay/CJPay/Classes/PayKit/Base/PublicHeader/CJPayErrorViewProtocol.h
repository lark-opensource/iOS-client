//
//  CJPayErrorViewProtocol.h
//  Pods
//
//  Created by 王新华 on 3/4/20.
//

#ifndef CJPayErrorViewProtocol_h
#define CJPayErrorViewProtocol_h

typedef NS_ENUM(NSUInteger, CJPayErrorViewStyle) {
    CJPayErrorViewStyleLight = 0,
    CJPayErrorViewStyleDark,
};

typedef NS_ENUM(NSUInteger, CJPayErrorViewAction) {
    CJPayErrorViewActionRetry = 0,
};

typedef void(^CJPayErrorViewActionBlock) (CJPayErrorViewAction);

// 异常页面定义
@protocol CJPayErrorViewProtocol <NSObject>

// 根据style参数返回指定主题下的异常view
// 其中view的大小为屏幕宽高
// 在view中有点击事件时，可以通过actionBlock进行回调。目前只有一种action，CJPayErrorViewActionRetry
- (UIView *)errorViewFor:(CJPayErrorViewStyle)style edgeInsets:(UIEdgeInsets)edgeInsets actionBlock:(CJPayErrorViewActionBlock)actionBlock;

@end

#endif /* CJPayErrorViewProtocol_h */
