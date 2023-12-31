//
//  BDUGAdditionalPanelContentItem.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/4/30.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGShareBaseContentItem.h"

@class BDUGSharePanelContent;
@class BDUGShareManager;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeAdditionalPanel;

@interface BDUGAdditionalPanelContentItem : BDUGShareBaseContentItem

@property (nonatomic, strong) BDUGSharePanelContent *panelContent;
@property (nonatomic, weak) BDUGShareManager *shareManager;

@end

NS_ASSUME_NONNULL_END
