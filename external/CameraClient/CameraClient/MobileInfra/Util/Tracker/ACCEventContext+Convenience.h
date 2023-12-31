//
//  ACCEventContext+Convenience.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import "ACCEventContext.h"

@interface ACCEventContext (Convenience)
+ (instancetype)contextMakeBaseAttributes:(void(^)(ACCAttributeBuilder *build))block;
@end
