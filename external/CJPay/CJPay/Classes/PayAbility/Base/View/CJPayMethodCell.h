//
//  CJPayMethodCell.h
//  Pods
//
//  Created by wangxiaohong on 2020/4/9.
//

#import <UIKit/UIKit.h>
#import "CJPayMehtodDataUpdateProtocol.h"
#import "CJPayLoadingManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMethodCell : UITableViewCell<CJPayMethodDataUpdateProtocol, CJPayBaseLoadingProtocol>

@end

NS_ASSUME_NONNULL_END
