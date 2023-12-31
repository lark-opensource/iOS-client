//
//  BDUGLarkActivity.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/3/27.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGActivityProtocol.h"
#import "BDUGLarkContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToLark;

@interface BDUGLarkActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGLarkContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END
