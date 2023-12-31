//
//  AWERepoShareModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/25.
//

#import "AWERepoShareModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "ACCFriendsServiceProtocol.h"
#import "ACCPublishPrivacySecurityManagerProtocol.h"

@interface AWEVideoPublishViewModel (AWERepoShare) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoShare)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoShareModel.class];
	return info;
}

- (AWERepoShareModel *)repoShare
{
    AWERepoShareModel *shareModel = [self extensionModelOfClass:AWERepoShareModel.class];
    NSAssert(shareModel, @"extension model should not be nil");
    return shareModel;
}

@end

@implementation AWERepoShareModel

#pragma mark - publish

- (nullable NSString *)shareShootWay
{
    if (self.thirdAppKey.length == 0) {
        return nil;
    }
    NSString *md5 = [self.thirdAppKey acc_md5String];
    if ([md5 isEqual:@"300569c31ae345182a3f0361fd52e6dc"] || [md5 isEqual:@"4f0a9ee3aa728262b88d24b31b946040"]) {
        return @"lv_sync";
    } else if ([md5 isEqual:@"ba3cf5b84ac0572466b4b7210bb0e0c3"] || [md5 isEqual:@"ba3cf5b84ac0572466b4b7210bb0e0c3"]) {
        return @"beautyme_sync";
    } else if ([md5 isEqual:@"a6cfea10b99a5c658b2a036ddb67d32a"] || [md5 isEqual:@"74792fc52eba5cd3c8ef04b879fbe5dd"]) {
        return @"retouch_sync"; // General version: awbojmysanphc8b0; Inhouse version: awz8d43dihoyq67j
    }
    return nil;
}

#pragma mark - copying

- (id)copyWithZone:(NSZone *)zone {
    AWERepoShareModel *model = [super copyWithZone:zone];
    
    // 是否来自第三方
    model.thirdAppName = self.thirdAppName;
    model.shareToPublish = self.shareToPublish;

    return model;
}

/*
！！！发布请求参数相关看这里！！！
 在发布请求参数打包的时候会遍历element中的acc_publishRequestParams得到额外的参数，并塞入原参数集合中（平级）；
 因此只需要在此处编写约定好的key-value即可；[NSNull null]最为空占位，在后续的流程中会被过滤掉。
 */
#pragma mark - ACCRepositoryRequestParamsProtocol - Optional

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    [[IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) publishPrivacySecurityManager] resetSyncModelWithPrivacyCheck:publishViewModel];
    
    NSMutableDictionary *mutableParameter = @{}.mutableCopy;
    [mutableParameter setObject:@(self.syncToToutiao) forKey:@"sync_to_toutiao"];
    [mutableParameter setObject:@(self.syncToToutiao) forKey:@"sync_to_xigua"];
    if (!ACC_isEmptyString(self.thirdAppKey)) {
        mutableParameter[@"open_platform_key"] = self.thirdAppKey;
    }
    
    return mutableParameter.copy;
}
@end
