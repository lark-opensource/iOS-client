//
//  TTVideoEnginePlayInfo.m
//  Pods
//
//  Created by guikunzhi on 2017/6/12.
//
//

#import "TTVideoEnginePlayInfo.h"
#import "TTVideoEngine.h"
#import "TTVideoEngineInfoModel.h"
#import "NSDictionary+TTVideoEngine.h"
#import "NSObject+TTVideoEngine.h"

@implementation TTVideoEnginePlayInfo
/// Please use @property.

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    if (self = [super init]) {
        _videoInfo = [[TTVideoEngineInfoModel alloc] initWithDictionary:jsonDict encrypted:NO];
    }
    return self;
}

- (NSArray *)allURLWithDefinitionType:(TTVideoEngineResolutionType)type transformedURL:(BOOL)transformed {
    if (self.videoInfo) {
        return [self.videoInfo allURLWithDefinition:type transformedURL:transformed];
    }
    
    return nil;
}

- (TTVideoEngineURLInfo *)videoInfoForType:(TTVideoEngineResolutionType)type {
    return [self.videoInfo videoInfoForType:type];
}

- (TTVideoEngineURLInfo *)videoInfoForType:(TTVideoEngineResolutionType)type otherCondition:(NSMutableDictionary *)searchCondition {
    return [self.videoInfo videoInfoForType:type];
}

- (NSArray<NSNumber *> *)supportedResolutionTypes {
    if (self.videoInfo) {
        return [self.videoInfo supportedResolutionTypes];
    }
    return nil;
}

- (NSArray<NSString *> *)supportedQualityInfos {
    if (self.videoInfo) {
        return [self.videoInfo supportedQualityInfos];
    }
    return nil;
}

///MARK: - NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end
