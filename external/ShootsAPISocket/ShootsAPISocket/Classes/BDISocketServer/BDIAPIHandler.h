//
//  BDIAPIHandler.h
//  BDiOSpy
//
//  Created by byte dance on 2021/11/19.
//

#import <Foundation/Foundation.h>
#import "BDIRPCRoute.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDIAPIHandler <NSObject>

+ (NSArray<BDIRPCRoute *> *)routes;

@optional
+ (BOOL)shouldRegisterAutomatically;

@end

NS_ASSUME_NONNULL_END
