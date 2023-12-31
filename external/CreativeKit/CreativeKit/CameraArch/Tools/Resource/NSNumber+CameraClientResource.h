//
//  NSNumber+CameraClientResource.h
//  CameraClient
//
//  Created by Liu Deping on 2020/4/8.
//

#import <Foundation/Foundation.h>

extern int ACCIntConfig(NSString *name);
extern BOOL ACCBoolConfig(NSString *name);
extern CGFloat ACCFloatConfig(NSString *name);
extern NSNumber *ACCNumberConfig(NSString *name);

NS_ASSUME_NONNULL_BEGIN

@interface NSNumber (CameraClientResource)

+ (BOOL)acc_boolValueWithName:(NSString *)name;

+ (CGFloat)acc_floatValueWithName:(NSString *)name;

+ (int)acc_intValueWithName:(NSString *)name;

+ (NSNumber *)acc_numberWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
