//
//  AWEStickerDataManager+AWEConvenience.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2021/4/2.
//

#import "AWEStickerDataManager+AWEConvenience.h"
#import "ACCLocationProtocol.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "IESEffectModel+DStickerAddditions.h"

@implementation AWEStickerDataManager (AWEConvenience)

- (instancetype)initWithPanelType:(AWEStickerPanelType)type
{
    self = [self initWithPanelType:type configExtraParamsBlock:^{
        [EffectPlatform setExtraPerRequestNetworkParametersBlock:^NSDictionary *{
            return @{
                @"city_code" : [ACCLocation() currentSelectedCityCode] ?: @""
            };
        }];
    }];
    
    [self.needFilterEffect addPredicate:^BOOL(IESEffectModel * _Nullable input, __autoreleasing id * _Nullable output) {
        // 对非抖音卡用户过滤抖音卡专属贴纸
        return [input isDouyinCard] && !([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].isFreeFlowCardUser);
    } with:self];
    return self;
}

@end
