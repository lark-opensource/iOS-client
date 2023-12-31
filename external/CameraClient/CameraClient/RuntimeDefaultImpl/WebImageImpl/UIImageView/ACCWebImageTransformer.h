//
//  ACCWebImageTransformer.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <BDWebImage/BDBaseTransformer.h>
#import "ACCWebImageTransformProtocol.h"

@interface ACCWebImageTransformer : BDBaseTransformer
+ (nonnull instancetype)transformWithObject:(id <ACCWebImageTransformProtocol>)transformer;

@end

