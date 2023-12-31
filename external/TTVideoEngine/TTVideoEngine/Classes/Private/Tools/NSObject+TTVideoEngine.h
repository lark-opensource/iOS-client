//
//  NSObject+TTVideoEngine.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/7/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef __TTVIDEOENGINE_NSSECURECODING__
#define __TTVIDEOENGINE_NSSECURECODING__
#define TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON \
+ (BOOL)supportsSecureCoding {\
    return YES;\
}\
- (instancetype)initWithCoder:(NSCoder *)decoder {\
    self = [self init];\
    if (!self) {\
        return nil;\
    }\
    [self ttvideoengine_initWithCoder:decoder];\
    return self;\
}\
- (void)encodeWithCoder:(NSCoder *)coder {\
    [self ttvideoengine_encodeWithCoder:coder];\
}
#endif


@interface NSObject (TTVideoEngine)


- (NSString *)ttvideoengine_debugDescription;

- (void)ttvideoengine_initWithCoder:(NSCoder *)aDecoder;

- (void)ttvideoengine_encodeWithCoder:(NSCoder *)aCoder;

@end

NS_ASSUME_NONNULL_END
