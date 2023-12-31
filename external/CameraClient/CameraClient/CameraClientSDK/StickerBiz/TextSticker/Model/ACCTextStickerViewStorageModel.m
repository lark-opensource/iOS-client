//
//  ACCTextStickerStorageModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/16.
//

#import "ACCTextStickerViewStorageModel.h"
#import "ACCTextStickerView.h"
#import "ACCSerialization.h"
#import "ACCCommonStickerConfig.h"
#import <CreativeKitSticker/ACCStickerProtocol.h>

#import <libextobjc/extobjc.h>

@implementation ACCTextStickerViewStorageModel

- (ACCCommonStickerConfigStorageModel *)config
{
    if (!_config) {
        _config = [[ACCCommonStickerConfigStorageModel alloc] init];
    }
    
    return _config;
}

- (BOOL)accs_customCheckAcceptClass:(Class)checkClass isSave:(BOOL)isSave
{
    if (isSave) {
        if ([checkClass conformsToProtocol:@protocol(ACCStickerProtocol)]) {
            return YES;
        }
    } else {
        if ([checkClass isEqual:ACCTextStickerView.class] ||
            [checkClass isEqual:ACCCommonStickerConfig.class] ||
            [checkClass isSubclassOfClass:ACCCommonStickerConfig.class]) {
            return YES;
        }
    }
    
    return NO;;
}

- (__kindof NSObject *)accs_customRestoreOriginObj:(Class)originClass
{
    if ([originClass isEqual:ACCTextStickerView.class]) {
        return [[ACCTextStickerView alloc] initWithTextInfo:self.textModel options:ACCTextStickerViewAbilityOptionsNone];
    } else if ([originClass isEqual:ACCCommonStickerConfig.class] ||
               [originClass isSubclassOfClass:ACCCommonStickerConfig.class]) {
        ACCCommonStickerConfig *config = [ACCSerialization restoreFromObj:self.config to:originClass];
        return config;
    }
    
    return nil;
}

+ (id)accs_includeKeys:(BOOL)isSave
{
    if (isSave) {
        return nil;
    } else {
        return @{NSStringFromClass(ACCTextStickerView.class): @[@keypath(ACCTextStickerViewStorageModel.new, textStickerId),
                                                                @keypath(ACCTextStickerViewStorageModel.new, stickerID),
                                                                @keypath(ACCTextStickerViewStorageModel.new, timeEditingRange)]};
    }
}

+ (id)accs_covertRelations:(Class)originClass
{
    if ([originClass conformsToProtocol:@protocol(ACCStickerProtocol)]) {
        return
        @{NSStringFromClass(originClass): @{
                  @keypath(ACCTextStickerViewStorageModel.new, textStickerId): [@[
                      @keypath(((id<ACCStickerProtocol>)NSObject.new), contentView),
                      @keypath(ACCTextStickerViewStorageModel.new, textStickerId)
                  ] componentsJoinedByString:@"."],
                  @keypath(ACCTextStickerViewStorageModel.new, stickerID): [@[
                      @keypath(((id<ACCStickerProtocol>)NSObject.new), contentView),
                      @keypath(ACCTextStickerViewStorageModel.new, stickerID)
                  ] componentsJoinedByString:@"."],
                  @keypath(ACCTextStickerViewStorageModel.new, textModel): [@[
                      @keypath(((id<ACCStickerProtocol>)NSObject.new), contentView),
                      @keypath(ACCTextStickerViewStorageModel.new, textModel)
                  ] componentsJoinedByString:@"."],
                  @keypath(ACCTextStickerViewStorageModel.new, timeEditingRange): [@[
                      @keypath(((id<ACCStickerProtocol>)NSObject.new), contentView),
                      @keypath(ACCTextStickerViewStorageModel.new, timeEditingRange)
                  ] componentsJoinedByString:@"."]
            }
        };
    }
    
    return nil;
}

- (void)accs_extraFinishTransform:(NSObject *)originObj
{
    if ([originObj conformsToProtocol:@protocol(ACCStickerProtocol)]) {
        NSObject<ACCStickerProtocol> *sticker = (id)originObj;
        ACCCommonStickerConfigStorageModel *config = [ACCSerialization transformOriginalObj:sticker.config
                                                                                  to:ACCCommonStickerConfigStorageModel.class];
        config.geometryModel = [ACCSerialization transformOriginalObj:sticker.stickerGeometry to:ACCStickerGeometryModelStorageModel.class];
        config.timeRangeModel = [ACCSerialization transformOriginalObj:sticker.stickerTimeRange to:ACCStickerTimeRangeModelStorageModel.class];
        self.config = config;
    }
}

@end
