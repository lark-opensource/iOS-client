//
//  ACCNLEBundleResource.m
//  Aweme
//
//  Created by raomengyun on 2021/11/9.
//

#import "ACCNLEBundleResource.h"
#import "ACCConfigKeyDefines.h"
#import "NLETrackSlot_OC+Extension.h"

#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <NLEPlatform/NLEResourceNode+iOS.h>
#import <TTVideoEditor/IESMMEffectStickerInfo.h>
#import <objc/runtime.h>

@implementation ACCNLEBundleResource

- (instancetype)init
{
    self = [super init];
    if (self) {
        _videoResourceUUIDs = [NSMutableDictionary<NSString *, AVAsset *> dictionary];
        _audioResourceUUIDs = [NSMutableDictionary<NSString *, AVAsset *> dictionary];
    }
    return self;
}

- (NSString *)resourcePathForNode:(NLEResourceNode_OC *)resourceNode
{
    if (resourceNode.resourceType == NLEResourceTypeEffect) {
        AWEEffectFilterPathBlock pathConvertBlock = self.nle.effectPathBlock;
        if (pathConvertBlock == NULL) {
            pathConvertBlock = [[AWEEffectFilterDataManager defaultManager] pathConvertBlock];
        }
        if (pathConvertBlock != NULL &&
            resourceNode.resourceId.length > 0) {
            return pathConvertBlock(resourceNode.resourceId, IESEffectFilterNone).path;
        }
    }
    return @"";
}

- (AVAsset *)assetForResourceNode:(NLEResourceNode_OC *)resourceNode
{
    if (ACCConfigBool(kConfigBool_disable_nle_asset_optimization)) {
        return nil;
    }
    return self.videoResourceUUIDs[resourceNode.UUID] ?: self.audioResourceUUIDs[resourceNode.UUID];
}

@end

@implementation NLEInterface_OC(BundleResource)

- (ACCNLEBundleResource *)acc_bundleResource
{
    ACCNLEBundleResource *bundleResource = objc_getAssociatedObject(self, @selector(acc_bundleResource));
    if (!bundleResource) {
        bundleResource = [[ACCNLEBundleResource alloc] init];
        bundleResource.nle = self;
        objc_setAssociatedObject(self, @selector(acc_bundleResource), bundleResource, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return bundleResource;
}

- (BOOL)acc_slot:(NLETrackSlot_OC *)slot isRelateWithAsset:(AVAsset *)asset
{
    if (ACCConfigBool(kConfigBool_disable_nle_asset_optimization)) {
        if (slot.segment.getResNode.resourceType == NLEResourceTypeVideo ||
            slot.segment.getResNode.resourceType == NLEResourceTypeImage) {
            return [slot isRelatedWithVideoAsset:asset];
        } else if (slot.segment.getResNode.resourceType == NLEResourceTypeAudio) {
            return [slot isRelatedWithAudioAsset:asset];
        } else {
            return NO;
        }
    } else {
        AVAsset *slotAsset = [self assetFromSlot:slot];
        return slotAsset && asset && [slotAsset isEqual:asset];
    }
}

- (void)acc_appendBundleResourceFrom:(NLEInterface_OC *)nle
{
    [self.acc_bundleResource.videoResourceUUIDs addEntriesFromDictionary:nle.acc_bundleResource.videoResourceUUIDs];
    [self.acc_bundleResource.audioResourceUUIDs addEntriesFromDictionary:nle.acc_bundleResource.audioResourceUUIDs];
}

@end
