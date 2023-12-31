//
//  ACCStickerCompoundApplyHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/7/27.
//

#import "ACCStickerCompoundHandler.h"
#import "ACCStickerHandler+Private.h"

@interface ACCStickerCompoundHandler ()

@property (nonatomic, strong) NSMutableArray<ACCStickerHandler *> *internalHandlers;

@end

@implementation ACCStickerCompoundHandler
@dynamic stickerContainerView;
@dynamic uiContainerView;
@dynamic player;
@dynamic logger;
@synthesize stickerContainerIndex;

+ (instancetype)compoundHandler {
    ACCStickerCompoundHandler *handler = [[self alloc] init];
    return handler;
}

- (void)apply:(UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx {
    for (ACCStickerHandler *handler in self.internalHandlers) {
        if ([handler canHandleSticker:sticker]) {
            [handler apply:sticker index:idx];
        }
    }
}

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker {
    for (ACCStickerHandler *handler in self.internalHandlers) {
        if ([handler canRecoverSticker:sticker]) {
            [handler recoverSticker:sticker];
        }
    }
}

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker {
    return YES;
}

- (BOOL)canRecoverSticker:(nonnull ACCRecoverStickerModel *)sticker {
    return YES;
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig onCompletion:(void (^)(void))completionHandler
{
    BOOL handled = NO;
    for (ACCStickerHandler *handler in self.internalHandlers) {
        if ([handler canExpressSticker:stickerConfig]) {
            handled = YES;
            [handler expressSticker:stickerConfig onCompletion:completionHandler];
            // one config can only be consumed by once
            break;
        }
    }
    if (!handled) {
        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    for (ACCStickerHandler *handler in self.internalHandlers) {
        if ([handler canExpressSticker:stickerConfig]) {
            [handler expressSticker:stickerConfig];
            break;
        }
    }
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex {
    for (ACCStickerHandler *handler in self.internalHandlers) {
        [handler addInteractionStickerInfoToArray:interactionStickers idx:stickerIndex];
    }
}

- (void)finish {
    for (ACCStickerHandler *handler in self.internalHandlers) {
        [handler finish];
    }
}

- (void)reset {
    for (ACCStickerHandler *handler in self.internalHandlers) {
        [handler reset];
    }
}

- (void)updateSticker:(NSInteger)stickerId withNewId:(NSInteger)newId {
    for (ACCStickerHandler *handler in self.internalHandlers) {
        [handler updateSticker:stickerId withNewId:newId];
    }
}

- (void)addHandler:(ACCStickerHandler *)handler {
    handler.stickerContainerLoader = self.stickerContainerLoader;
    handler.logger = self.logger;
    handler.stickerContainerView = self.stickerContainerView;
    handler.uiContainerView = self.uiContainerView;
    handler.editSticker = self.editSticker;
    handler.player = self.player;
    
    [self.internalHandlers addObject:handler];
}

- (NSMutableArray *)internalHandlers {
    if (!_internalHandlers) {
        _internalHandlers = @[].mutableCopy;
    }
    return _internalHandlers;
}

- (NSArray<ACCStickerHandler *> *)handlers
{
    return [self.internalHandlers copy];
}

#pragma mark - property

// what the fuck logic does!!!
- (ACCStickerContainerView *)stickerContainerView {
    ACCStickerHandler *handler = self.internalHandlers.firstObject;
    return handler.stickerContainerView;
}

- (void)setPlayer:(id<ACCStickerPlayerApplying>)player {
    [super setPlayer:player];
    
    for (ACCStickerHandler *handler in self.internalHandlers) {
        handler.player = player;
    }
}

- (void)setEditSticker:(id<ACCEditStickerProtocol>)editSticker {
    [super setEditSticker:editSticker];
    
    for (ACCStickerHandler *handler in self.internalHandlers) {
        handler.editSticker = editSticker;
    }
}

- (void)setUiContainerView:(UIView *)uiContainerView {
    [super setUiContainerView:uiContainerView];
    
    for (ACCStickerHandler *handler in self.internalHandlers) {
        handler.uiContainerView = uiContainerView;
    }
}

- (void)setLogger:(id<ACCStickerLogger>)logger {
    [super setLogger:logger];
    
    for (ACCStickerHandler *handler in self.internalHandlers) {
        handler.logger = logger;
    }
}

- (void)setStickerContainerLoader:(ACCStickerContainerView *(^)(void))stickerContainerLoader {
    [super setStickerContainerLoader:stickerContainerLoader];
    
    for (ACCStickerHandler *handler in self.internalHandlers) {
        handler.stickerContainerLoader = stickerContainerLoader;
    }
}

@end
