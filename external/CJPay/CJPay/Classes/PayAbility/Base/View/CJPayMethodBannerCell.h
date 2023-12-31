//
//  CJPayMethodBannerCell.h
//  Pods
//
//  Created by youerwei on 2021/4/12.
//

#import <UIKit/UIKit.h>
#import "CJPayMehtodDataUpdateProtocol.h"



NS_ASSUME_NONNULL_BEGIN

typedef void (^CJPayBannerClickBlock)(CJPayChannelType);

@class CJPayButton;
@class CJPayChannelBizModel;
@interface CJPayMethodBannerCell : UITableViewCell<CJPayMethodDataUpdateProtocol>

@property (nonatomic, strong, readonly) UILabel *bannerTextLabel;
@property (nonatomic, strong, readonly) CJPayButton *combinePayButton;
@property (nonatomic, copy) CJPayBannerClickBlock clickBlock;

- (void)updateContent:(CJPayChannelBizModel *)model;
NS_ASSUME_NONNULL_END

@end
