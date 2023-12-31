//
//  LVTemplateChecker.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/9/2.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"
#import "LVModelType.h"

typedef NS_ENUM(NSUInteger, LVMediaDraftVersionStatus) {
    LVMediaDraftVersionStatusTotalEqual,
    LVMediaDraftVersionStatusMaxVersionLargeOrEqual,
    LVMediaDraftVersionStatusMaxVersionMin,
};

NS_ASSUME_NONNULL_BEGIN

@interface LVTemplateChecker : NSObject



@end

@interface LVMediaDraft (PlatformSupport)

- (LVMediaDraftVersionStatus)checkVersion;

- (LVMutablePayloadPlatformSupport)supportPlatform;

- (NSArray<NSString *>*)supportPlatforms;

@end

NS_ASSUME_NONNULL_END
