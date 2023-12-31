//
//  CJPayMethodUnbindCardZoneCell.h
//  cjpayBankLock
//
//  Created by shanghuaijun on 2023/2/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol  CJPayMethodDataUpdateProtocol;
@interface CJPayMethodUnbindCardZoneCell : UITableViewCell<CJPayMethodDataUpdateProtocol>

@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
