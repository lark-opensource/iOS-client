//
//  BDUGAdditionalPanelActivity.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/5/6.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGActivityProtocol.h"
#import "BDUGAdditionalPanelContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypeAdditionalPanel;
extern NSString * const BDUGAdditionalPanelErrorDomain;

@interface BDUGAdditionalPanelActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGAdditionalPanelContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END
