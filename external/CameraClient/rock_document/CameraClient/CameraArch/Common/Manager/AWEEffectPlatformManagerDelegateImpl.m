//
//  AWEEffectPlatformManagerDelegateImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2021/4/7.
//

#import "AWEEffectPlatformManagerDelegateImpl.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "IESEffectModel+DStickerAddditions.h"

@implementation AWEEffectPlatformManagerDelegateImpl

- (BOOL)shouldFilterEffect:(nonnull IESEffectModel *)effect {
    // 对非抖音卡用户过滤抖音卡专属贴纸
    return [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].isFreeFlowCardUser && ![effect isDouyinCard];
}

@end
