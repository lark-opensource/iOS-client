//
//  LVPayloadPool.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"
#import "LVDraftPayload.h"
#import "LVDraftTailLeaderPayload.h"
#import "LVDraftVideoPayload.h"
#import "LVDraftAudioPayload.h"
#import "LVDraftImagePayload.h"
#import "LVDraftTextPayload.h"
#import "LVDraftEffectPayload.h"
#import "LVDraftStickerPayload.h"
#import "LVDraftCanvasPayload.h"
#import "LVDraftTransitionPayload.h"
#import "LVDraftAudioFadePayload.h"
#import "LVDraftAudioEffectPayload.h"
#import "LVDraftBeatsPayload.h"
#import "LVDraftAnimationPayload.h"
#import "LVDraftPlaceholderPayload.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVPayloadPool (Interface)

- (NSDictionary<NSString*, LVDraftPayload*>*)allPayloads;

@end

NS_ASSUME_NONNULL_END
