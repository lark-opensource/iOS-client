//
//  TSPKPipelineSwizzleUtil.h
//  Musically
//
//  Created by ByteDance on 2022/11/24.
//

#import <Foundation/Foundation.h>
#import "TSPKDetectPipeline.h"

@interface TSPKPipelineSwizzleUtil : NSObject

+ (void)swizzleMethodWithPipelineClass:(Class _Nullable)pipelineClass clazz:(Class _Nullable)clazz;

@end

