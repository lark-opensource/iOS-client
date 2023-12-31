//
// Created by duanefaith on 2019/10/12.
//

#import "NSString+BulletXUUID.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (BulletXUUID)

+ (nonnull NSString *)bullet_UUID
{
    CFUUIDRef unique = CFUUIDCreate(kCFAllocatorDefault);
    NSString *result = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, unique));
    CFRelease(unique);
    return result;
}

@end

NS_ASSUME_NONNULL_END
