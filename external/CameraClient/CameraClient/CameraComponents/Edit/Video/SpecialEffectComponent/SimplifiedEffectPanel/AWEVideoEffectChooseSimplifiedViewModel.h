//
//  AWEVideoEffectChooseSimplifiedViewModel.h
//  Indexer
//
//  Created by Daniel on 2021/11/8.
//

#import <Foundation/Foundation.h>

#import "AWEVideoEffectChooseSimplifiedCellModel.h"

@class AWEVideoPublishViewModel;
@protocol ACCEditServiceProtocol;

@interface AWEVideoEffectChooseSimplifiedViewModel : NSObject

@property (nonatomic, weak, readonly, nullable) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, copy, readonly, nullable) NSArray<AWEVideoEffectChooseSimplifiedCellModel *> *cellModels;
@property (nonatomic, assign) NSInteger selectedIndex;

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService;

- (void)updateCellModelsWithCachedEffects;
- (void)getEffectsInPanel:(void (^ _Nullable)(void))completion;
- (void)downloadEffectAtIndex:(NSUInteger)index completion:(void (^)(BOOL))completion;
- (void)applyEffectWholeRange:(NSString *)effectId;
- (void)removeAllEffects;

@end
