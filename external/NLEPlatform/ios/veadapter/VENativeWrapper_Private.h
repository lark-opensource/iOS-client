//
//  VENativeWrapper_Private.h
//  Pods
//
//  Created by bytedance on 2021/1/19.
//

#ifndef VENativeWrapper_Private_h
#define VENativeWrapper_Private_h

#import <Foundation/Foundation.h>
#import "VENativeWrapper.h"
#import "NLESequenceNode.h"
#import "NLEStyle.h"
#import "NLEConstDefinition.h"
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import "NLEVideoDataUpdateInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Private)

- (void)p_updateVolumForAsset:(AVAsset *)asset
                      isVideo:(BOOL)isVideo
                     withSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                     prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

- (void)p_updateClipRangeForAsset:(AVAsset *)asset
                         WithSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                         prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

- (void)p_updatePitchFilterForAsset:(AVAsset *)asset
                            isVideo:(BOOL)isVideo
                            forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                           prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

- (void)p_updatePitchV2FilterForAsset:(AVAsset *)asset
                            isVideo:(BOOL)isVideo
                            forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                             prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

- (NSString *)audioFilterCacheKeyForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

//- (void)removeCachedFilterAmazingFeaturesForVideoSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)removeAudioFilterForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

/// filter key frame
- (void)syncFilterKeyFrame:(std::vector<NodeChangeInfo> &)changeInfos
                  forTrack:(std::shared_ptr<const cut::model::NLETrack>)track;


/// amazing filter

- (void)addAmazingFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
                 forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateAmazingFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
             withPrevFilter:(std::shared_ptr<cut::model::NLEFilter>)prevFilter
                    forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)removeAmazingFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
                    forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)addGlobalAmazingFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateGlobalAmazingFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                         prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

- (void)removeGlobalAmazingFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot;


/// normal filter

- (void)addNormalFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
                forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateNormalFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
            withPrevFilter:(std::shared_ptr<cut::model::NLEFilter>)prevFilter
                   forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)removeNormalFilter:(std::shared_ptr<cut::model::NLEFilter>)filter
                   forSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)addGlobalNormalFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)updateGlobalNormalFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                        prevSlot:(std::shared_ptr<cut::model::NLETrackSlot>)prevSlot;

- (void)removeGlobalNormalFilter:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

@end

NS_ASSUME_NONNULL_END


#endif /* VENativeWrapper_Private_h */
