//
//  AWEWebImageTransformer.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <BDWebImage/BDBaseTransformer.h>
#import "AWEWebImageTransformProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEWebImageTransformer : NSObject
+ (nonnull instancetype)transformWithObject:(id <AWEWebImageTransformProtocol>)transformer;

@end

NS_ASSUME_NONNULL_END
