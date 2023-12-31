//
//  DVEVCContext.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DVEBusinessConfiguration.h"
#import "DVEEffectValue.h"
#import "DVEResourceLoaderProtocol.h"
#import "DVEResourcePickerProtocol.h"
#import <DVEFoundationKit/NLEResourceAV_OC+DVE.h>
#import <DVETrackKit/DVEMediaContext+AudioOperation.h>
#import <DVETrackKit/DVEMediaContext+Blend.h>
#import <DVETrackKit/DVEMediaContext+VideoOperation.h>
#import <DVETrackKit/DVEMediaContext+SlotUtils.h>
#import <DVETrackKit/DVEMediaContext.h>
#import <DVEFoundationKit/NLENode_OC+DVE.h>
#import <DVEFoundationKit/NLETimeSpaceNode_OC+DVE.h>
#import <DVEFoundationKit/NLETrackSlot_OC+DVE.h>
#import <DVEFoundationKit/NLEVideoAnimation_OC+DVE.h>
#import <NLEPlatform/NLEInterface.h>
#import <DVEFoundationKit/NSArray+DVE.h>

#import "DVEVCContextServiceProvider.h"
#import "DVECoreCanvasProtocol.h"
#import "DVECoreSlotProtocol.h"
#import "DVECoreStickerProtocol.h"
#import "DVECoreVideoProtocol.h"
#import "DVECoreKeyFrameProtocol.h"
#import "DVECoreActionServiceProtocol.h"
#import "DVECoreDraftServiceProtocol.h"
#import "DVECoreExportServiceProtocol.h"
#import "DVEPlayerServiceProtocol.h"
#import "DVENLEEditorProtocol.h"
#import "DVENLEInterfaceProtocol.h"

#if ENABLE_TEMPLATETOOL
#import "DVECoreTemplateProtocol.h"
#endif

#if ENABLE_MULTITRACKEDITOR
#import "DVECoreAnimationProtocol.h"
#import "DVECoreAudioProtocol.h"
#import "DVECoreEffectProtocol.h"
#import "DVECoreFilterProtocol.h"
#import "DVECoreMaskProtocol.h"
#import "DVECoreRegulateProtocol.h"
#import "DVECoreTextProtocol.h"
#import "DVECoreTextTemplateProtocol.h"
#import "DVECoreTransitionProtocol.h"
#import "DVECoreImportServiceProtocol.h"
#endif

@interface DVEVCContext : NSObject

///DI 注入服务提供者
@property (nonatomic, strong, readonly) id<DVEDIServiceProvider> serviceProvider;

// 轨道区上下文
@property (nonatomic, strong, readonly) DVEMediaContext *mediaContext;

// 播放器职责承担者
@property (nonatomic, strong, readonly) id<DVEPlayerServiceProtocol> playerService;

- (instancetype)initWithBusinessConfiguration:(DVEBusinessConfiguration *)config;

@end
