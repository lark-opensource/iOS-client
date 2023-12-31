//
//  AWEVideoPublishViewModel.m
//  Aweme
//
//  Created by Quan Quan on 16/8/28.
//  Copyright  ©  2016 byedance. All rights reserved
//

#import "AWEVideoPublishViewModel.h"
#import "AWEVideoPublishViewModel+Repository.h"
#import <CreativeKit/ACCMacros.h>

@implementation AWEVideoPublishSourceInfo
- (NSDictionary *)jsonInfo
{
    if (self.descriptionInfo != nil) {
        NSDictionary *info = [NSDictionary dictionaryWithDictionary:self.descriptionInfo];
        return info;
    }
    return nil;
}

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        self.descriptionInfo = dic;
    }
    return self;
}
@end

@implementation AWEVideoPublishAwemeInfo

@end


@interface AWEVideoPublishViewModel ()

@end

@implementation AWEVideoPublishViewModel

+ (NSString *)createIDWithTaskID:(NSString *)taskID deviceID:(NSString *)deviceID UUID:(NSString *)UUID
{
    if (!deviceID) {
        deviceID = [UUID stringByReplacingOccurrencesOfString:@"-" withString:@""];
    }
    
    return [NSString stringWithFormat:@"%@%@", deviceID, taskID];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (void)setupData
{
    _awemeInfo = [[AWEVideoPublishAwemeInfo alloc] init];
    // setup repository data
    [self setupRegisteredRepositoryElements];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    AWEVideoPublishViewModel *model = [super copyWithZone:zone];
    
    model.awemeInfo = self.awemeInfo;
    model.extensionModels = [self deepCopyExtensionModels];
    
    return model;
}

#pragma mark - overwrite

- (void)setupRegisteredRepositoryElements
{
    [super setupRegisteredRepositoryElements];
    for (ACCRepositoryRegisterInfo *registerInfo in self.registerNodeInfo.allValues) {
        if (registerInfo.childNode) {
            continue;
        }
        if (registerInfo.initialWhenSetup) {
            id repoModelPayload = [[registerInfo.classInfo alloc] init];
            [self setExtensionModelByClass:repoModelPayload];
        }
    }
}

- (void)copyPublishModelFrom:(AWEVideoPublishViewModel *)from
{
    [self assignCopyPublishViewModelTo:self from:from];
}

- (void)assignCopyPublishViewModelTo:(AWEVideoPublishViewModel *)to from:(AWEVideoPublishViewModel *)from
{
    to.awemeInfo = from.awemeInfo;
    to.extensionModels = [from deepCopyExtensionModels];
}

+ (void)shadowCopyPublishViewModelTo:(AWEVideoPublishViewModel *)to from:(AWEVideoPublishViewModel *)from {
    to.awemeInfo = from.awemeInfo;
    to.extensionModels = from.extensionModels;
}

@end

