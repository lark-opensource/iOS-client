//
//  CFValidate.h
//  CoreFoundation
//
//  Created by sunrunwang on 2019/5/27.
//  Copyright © 2019 Bill Sun. All rights reserved.
//
#ifdef DEBUG

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    CAValidateTypeImmutable = 1 << 0,
    CAValidateTypeImmutableAllowNonStandardClass = 1 << 1,
    CAValidateTypeJSON = 1 << 2,
    CAValidateTypePlist = 1 << 3
} CAValidateType;

@interface NSObject (CaptainAllred_Validate)

- (BOOL)hmd_performValidate:(CAValidateType)type
             saveResult:(NSMutableString * _Nullable)storage
            prefixBlank:(NSUInteger)prefixBlank
          increaseblank:(NSUInteger)increaseBlank;

@end

NS_ASSUME_NONNULL_END

#endif
