//
//  CJPayQuickBindCardViewModel.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/13.
//

#import "CJPayBaseListViewModel.h"
#import "CJPayLoadingManager.h"
#import "CJPayCardManageModule.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayQuickBindCardModel;

typedef void (^CJPayQuickBindCardViewModelDidSelectedBlock)(CJPayQuickBindCardModel *);

@interface CJPayQuickBindCardViewModel : CJPayBaseListViewModel <CJPayBaseLoadingProtocol>

@property (nonatomic, strong)  CJPayQuickBindCardModel *bindCardModel;
@property (nonatomic, assign) BOOL isBottomRounded; //底部是否设置为圆角
@property (nonatomic, assign) BOOL isBottomLineExtend;

@property (nonatomic, assign) CJPayBindCardStyle viewStyle;
@property (nonatomic, strong) CJPayQuickBindCardViewModelDidSelectedBlock didSelectedBlock;

@end

NS_ASSUME_NONNULL_END
