//
//  NSObject+TSAddition.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/15.
//

#import <Foundation/Foundation.h>



@interface NSObject (TSAddition)

+ (BOOL)ts_swizzleInstanceMethod:(SEL _Nullable)origSelector with:(SEL _Nullable)newSelector;

+ (BOOL)ts_swizzleClassMethod:(SEL _Nullable)origSelector with:(SEL _Nullable)newSelector;

/// origBackupSelectorClass is required when the origSelector method is not implemented and origBackupSelectorClass need  implement origSelector menthod.
+ (BOOL)ts_swzzileMethodWithOrigClass:(Class _Nullable)origClass origSelector:(SEL _Nullable)origSelector origBackupSelectorClass:(Class _Nullable)origBackupSelectorClass newSelector:(SEL _Nullable)newSelector newClass:(Class _Nullable)newClass;

+ (NSString *_Nullable)ts_className;

- (NSString *_Nullable)ts_className;

@end


