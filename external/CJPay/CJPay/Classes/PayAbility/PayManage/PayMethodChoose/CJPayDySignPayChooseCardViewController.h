//
//  CJPayDySignPayChooseCardViewController.h
//  CJPaySandBox
//
//  Created by ByteDance on 2023/6/30.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignPayChoosePayMethodManager;
@class CJPayDefaultChannelShowConfig;

typedef void (^CJPayDidSelectedBlock)(CJPayDefaultChannelShowConfig *selectedConfig, UIView *loadingView);

@interface CJPayDySignPayChooseCardViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy) CJPayDidSelectedBlock didSelectedBlock;
@property (nonatomic, copy) NSString *warningText;
@property (nonatomic, assign) CGFloat height;

- (instancetype)initWithManager:(CJPaySignPayChoosePayMethodManager *)manager;

@end

NS_ASSUME_NONNULL_END
