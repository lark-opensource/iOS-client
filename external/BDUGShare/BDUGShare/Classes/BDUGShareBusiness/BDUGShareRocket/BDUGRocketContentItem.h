//
//  BDUGRocketContentItem.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/21.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"
#import "BDUGRocketShare.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeRocket;

@interface BDUGRocketContentItem : BDUGShareBaseContentItem

@property (nonatomic, assign) BDUGRocketShareScene scene;

@end

NS_ASSUME_NONNULL_END
