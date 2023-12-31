//
//  LKHookUtil.h
//  LarkCrashSanitizer
//
//  Created by sniperj on 2019/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void SwizzleMethod(Class _originClass, SEL _originSelector, Class _newClass, SEL _newSelector);

bool SwizzleClassMethod(Class cls, SEL originalSelector, SEL swizzledSelector);

@interface LKHookUtil : NSObject

@end

NS_ASSUME_NONNULL_END
