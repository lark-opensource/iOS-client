//
//  ObjcExceptionHandler.h
//  LarkUIKit
//
//  Created by 姚启灏 on 2019/10/9.
//

#import <Foundation/Foundation.h>

@interface ObjcExceptionHandler : NSObject

+ (BOOL)catchException:(void(NS_NOESCAPE ^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
