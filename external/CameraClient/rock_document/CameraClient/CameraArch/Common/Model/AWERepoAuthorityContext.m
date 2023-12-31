//
//  AWERepoAuthorityContext.m
//  CameraClient-Pods-AwemeCore
//
//  Created by ZhangJunwei on 2021/10/22.
//

#import "AWERepoAuthorityContext.h"
#import <CreativeKit/ACCMacros.h>

@implementation AWERepoAuthorityContext

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.downloadIgnoreVisibility forKey:@"downloadIgnoreVisibility"];
    [coder encodeBool:self.duetIgnoreVisibility forKey:@"duetIgnoreVisibility"];
    [coder encodeBool:self.storyShareIgnoreVisibility forKey:@"storyShareIgnoreVisibility"];
    [coder encodeInteger:self.downloadVerificationStatus forKey:@"downloadVerificationStatus"];
    [coder encodeInteger:self.duetVerificationStatus forKey:@"duetVerificationStatus"];
    [coder encodeInteger:self.storyShareVerificationStatus forKey:@"storyShareVerificationStatus"];
    
    [coder encodeObject:self.downloadTypeErrorMessage forKey:@"downloadTypeErrorMessage"];
    [coder encodeObject:self.itemDuetErrorMessage forKey:@"itemDuetErrorMessage"];
    [coder encodeObject:self.itemShareErrorMessage forKey:@"itemShareErrorMessage"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _downloadIgnoreVisibility = [coder decodeBoolForKey:@"downloadIgnoreVisibility"];
        _duetIgnoreVisibility = [coder decodeBoolForKey:@"duetIgnoreVisibility"];
        _storyShareIgnoreVisibility = [coder decodeBoolForKey:@"storyShareIgnoreVisibility"];
        _downloadVerificationStatus = [coder decodeIntegerForKey:@"downloadVerificationStatus"];
        _duetVerificationStatus = [coder decodeIntegerForKey:@"duetVerificationStatus"];
        _storyShareVerificationStatus = [coder decodeIntegerForKey:@"storyShareVerificationStatus"];
        
        _downloadTypeErrorMessage = [coder decodeObjectForKey:@"downloadTypeErrorMessage"];
        _itemDuetErrorMessage = [coder decodeObjectForKey:@"itemDuetErrorMessage"];
        _itemShareErrorMessage = [coder decodeObjectForKey:@"itemShareErrorMessage"];
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    AWERepoAuthorityContext *context = [[AWERepoAuthorityContext alloc] init];
    context.downloadIgnoreVisibility = self.downloadIgnoreVisibility;
    context.duetIgnoreVisibility = self.duetIgnoreVisibility;
    context.storyShareIgnoreVisibility = self.storyShareIgnoreVisibility;
    context.downloadVerificationStatus = self.downloadVerificationStatus;
    context.duetVerificationStatus = self.duetVerificationStatus;
    context.storyShareVerificationStatus = self.storyShareVerificationStatus;
    context.downloadTypeErrorMessage = self.downloadTypeErrorMessage.copy;
    context.itemDuetErrorMessage = self.itemDuetErrorMessage.copy;
    context.itemShareErrorMessage = self.itemShareErrorMessage.copy;
    return context;
}

#pragma mark - Set Method

- (BOOL)isDownloadTypeError
{
    return !ACC_isEmptyString(self.downloadTypeErrorMessage);
}

- (BOOL)isItemDuetError
{
    return !ACC_isEmptyString(self.itemDuetErrorMessage);
}

- (BOOL)isItemShareError
{
    return !ACC_isEmptyString(self.itemShareErrorMessage);
}

@end
