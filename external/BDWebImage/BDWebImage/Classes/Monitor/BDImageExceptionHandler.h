//
//  BDImageExceptionHandler.h
//  BDWebImage
//
//  Created by 陈奕 on 2020/5/6.
//

#import <Foundation/Foundation.h>
#import "BDImagePerformanceRecoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDImageExceptionHandler : NSObject

+ (instancetype)sharedHandler;

- (void)registerRecord:(BDImagePerformanceRecoder *)record;

@end

NS_ASSUME_NONNULL_END
