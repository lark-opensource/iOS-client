//
//  NLEDataPackager.h
//  NLEPlatform
//
//  Created by bytedance on 2021/2/5.
//

#import <Foundation/Foundation.h>
#import "NLEStyle.h"
#import "NLESequenceNode.h"
#import "NLEResourceFinderProtocol.h"
#import <TTVideoEditor/HTSTransformFilter.h>
#import <TTVideoEditor/IESMMEffectConfig.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEDataPackager : NSObject

+ (TransformTextureVertices *)verticesForCrop:(std::shared_ptr<cut::model::NLEStyCrop>)crop;

+ (TransformTextureVertices *)verticesForClip:(std::shared_ptr<cut::model::NLEStyClip>)clip;

+ (NSArray<VEComposerInfo *> *)composerNodesForComposerFilter:(std::shared_ptr<cut::model::NLESegmentComposerFilter>)composerFilter
                                               resourceFinder:(id<NLEResourceFinderProtocol>)resourceFinder
                                                withIntensity:(BOOL)withIntensity;

@end

NS_ASSUME_NONNULL_END
