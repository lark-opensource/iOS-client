//
//   DVECoreProtocol.h
//   NLEEditor
//
//   Created  by bytedance on 2021/4/26.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>
#import "DVEEditorDoneEvent.h"

@class NLETrack_OC;
@class NLETrackSlot_OC;
@class NLEResourceNode_OC;
@class DVEVCContext;

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreProtocol <NSObject>

@property (nonatomic, weak) DVEVCContext *vcContext;

- (instancetype)initWithContext:(DVEVCContext *)context;

@end

NS_ASSUME_NONNULL_END
