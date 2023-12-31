//
//  CJPayMethodTableViewWithArrowCell.h
//  Pods
//
//  Created by 易培淮 on 2021/1/26.
//

#import <UIKit/UIKit.h>
#import "CJPayMehtodDataUpdateProtocol.h"
#import "CJPayUIMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMethodTableViewWithArrowCell : UITableViewCell <CJPayBaseLoadingProtocol >

@property (nonatomic, strong, readonly) UIImageView *arrowImageView;

@end

NS_ASSUME_NONNULL_END
