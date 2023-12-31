//
//  BDImageNSCache.h
//  BDWebImage
//
//  Created by 陈奕 on 2019/9/26.
//

#import <Foundation/Foundation.h>
#import "BDMemoryCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDImageNSCache <KeyType, ObjectType> : NSCache <KeyType, ObjectType> <BDMemoryCache>

@end

NS_ASSUME_NONNULL_END
