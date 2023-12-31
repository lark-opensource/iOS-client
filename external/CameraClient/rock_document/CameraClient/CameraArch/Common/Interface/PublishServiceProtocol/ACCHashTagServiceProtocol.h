//
//  ACCHashTagServiceProtocol.h
//  Pods
//
//  Created by 郝一鹏 on 2019/12/9.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCTextExtraProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCHashTagServiceProtocol <NSObject>

- (NSArray<id<ACCTextExtraProtocol>> *)resolveHashTagsWithText:(NSString *)text;

- (NSArray<NSString *> *)savedHashtags;

- (NSArray<NSString *> *)savedPrivateHashtags;

- (NSRegularExpression *)hashTagRegExp;

- (NSRegularExpression *)endWithHashTagRegExp;

- (void)historySaveHashTags:(NSArray<id<ACCTextExtraProtocol>> *)hashTags isPrivate:(BOOL)isPrivate;

@end

NS_ASSUME_NONNULL_END

FOUNDATION_STATIC_INLINE id<ACCHashTagServiceProtocol> ACCHashTagService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCHashTagServiceProtocol)];
}
