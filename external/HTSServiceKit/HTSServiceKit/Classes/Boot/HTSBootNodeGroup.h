//
//  HTSBootNodeGroup.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/15.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSBootInterface.h"
#import "HTSBootNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTSBootNodeGroup : NSObject<HTSBootNode>

- (instancetype)initWithSyncList:(HTSBootNodeList *)syncList
                       asyncList:(HTSBootNodeList *)asnycList;

@end

NS_ASSUME_NONNULL_END
