//
//  CJPayBytePayMethodView.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/13.
//

#import <UIKit/UIKit.h>

#import "CJPayChannelBizModel.h"
#import "CJPayLoadingManager.h"
#import "CJPayDefaultChannelShowConfig.h"

#define CJPayMethodQRCodePayCell_Class   @"CJPayMethodQRCodePayCell"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayMethodTableViewDelegate <NSObject>

- (void)didSelectAtIndex:(int) selectIndex;

@optional
- (void)didClickBannerWithType:(CJPayChannelType)channelType;
- (void)didChangeCreditPayInstallment:(NSString *)installment;

- (void)didSelectAtIndex:(int)selectIndex methodCell:(UITableViewCell * _Nonnull)cell; //增加协议将点击的cell透传出去，电商余额不足场景使用

- (void)didSelectNewCustomerSubCell:(NSInteger)selectIndex;
@end

@protocol CJPayMethodTableViewProtocol <CJPayBaseLoadingProtocol>

#pragma mark - delegate
@property (nonatomic, weak) id<CJPayMethodTableViewDelegate> _Nullable delegate;

#pragma mark - models
@property (nonatomic, copy) NSArray <CJPayChannelBizModel *>* _Nonnull models;

- (void)scrollToTop;

@end

@interface CJPayBytePayMethodView : UIView<CJPayMethodTableViewProtocol, UITableViewDelegate, UITableViewDataSource>

#pragma mark - flag
@property (nonatomic, assign) BOOL isChooseMethodSubPage;
@property (nonatomic, assign) BOOL isFromCombinePay;

@end

NS_ASSUME_NONNULL_END
