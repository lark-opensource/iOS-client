//
//  CJPayChoosePayMethodGroupView.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/22.
//

#import <UIKit/UIKit.h>
#import "CJPayLoadingManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayChooseDyPayMethodGroupModel;
@class CJPayBaseListCellView;
@class CJPayBaseListViewModel;
@class CJPayDefaultChannelShowConfig;
@class CJPayChooseDyPayMethodGroupModel;

@interface CJPayChoosePayMethodGroupView : UIView<CJPayBaseLoadingProtocol>

@property (nonatomic, copy) void(^cellWillDisplayBlock)(CJPayBaseListCellView *cell, CJPayBaseListViewModel *viewModel);

@property (nonatomic, copy) void(^didSelectedBlock)(CJPayDefaultChannelShowConfig *selectConfig, UIView *loadingView);//选中支付方式的回调
@property (nonatomic, copy) void(^contentHeightDidChangeBlock)(CGFloat newHeight);

- (instancetype)initWithPayMethodViewModel:(CJPayChooseDyPayMethodGroupModel *)model;
- (void)updatePayMethodViewBySelectConfig:(CJPayDefaultChannelShowConfig *)config;
@end

NS_ASSUME_NONNULL_END
