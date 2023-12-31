//
//  VETextPackager.h
//  NLEPlatform
//
//  Created by bytedance on 2021/2/7.
//

#import <Foundation/Foundation.h>
#import "NLESequenceNode.h"
#import "NLEResourceFinderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface VETextPackager : NSObject

+ (NSString *)textStickerParamWithSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                        resourceFinder:(id<NLEResourceFinderProtocol>)resourceFinder;

+ (NSString *)textTemplateDependResourceParamsOfSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                                      resourceFinder:(id<NLEResourceFinderProtocol>)resourceFinder;

+ (NSString *)textTemplateTextParamsOfSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                                     model:(std::shared_ptr<const cut::model::NLEModel>)model;

@end

NS_ASSUME_NONNULL_END
