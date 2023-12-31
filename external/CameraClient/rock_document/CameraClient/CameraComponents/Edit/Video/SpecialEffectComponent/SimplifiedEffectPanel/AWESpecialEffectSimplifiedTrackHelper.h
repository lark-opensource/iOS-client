//
//  AWESpecialEffectSimplifiedTrackHelper.h
//  Indexer
//
//  Created by Daniel on 2021/11/23.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@class IESEffectModel;

@interface AWESpecialEffectSimplifiedTrackHelper : NSObject

+ (void)trackClickEffectEntrance:(AWEVideoPublishViewModel *)publishModel;
+ (void)trackClickEffect:(AWEVideoPublishViewModel *)publishModel effectModel:(IESEffectModel *)effectModel;
+ (void)trackClearEffects;

@end
