//
//  ExtensionObjcExceptionHandler.h
//  LarkUIKit
//
//  Created by 王元洵 on 2022/04/22.
//

#import <Foundation/Foundation.h>

@interface ExtensionObjcExceptionHandler : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
