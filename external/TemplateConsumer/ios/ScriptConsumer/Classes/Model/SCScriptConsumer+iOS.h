//
//   SCScriptConsumer+iOS.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/6/1.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import "SCScriptModel+iOS.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^SCScriptConsumerAdjuectHandler)( NLETrackSlot_OC* _Nullable slot,NLEResourceType type);

typedef void (^SCScriptConsumerSortSlotHandler)( NLETrackSlot_OC* _Nullable preSlot,NSInteger index ,NLETrackSlot_OC* _Nullable curSlot);

@interface SCScriptConsumer_OC : NSObject


@property(nonatomic,copy)SCScriptConsumerAdjuectHandler adjustHandler;
@property(nonatomic,copy)SCScriptConsumerSortSlotHandler sortHandler;

- (BOOL)addScriptModel:(SCScriptModel_OC*)scriptModel nleModel:(NLEModel_OC*)nleModel;

@end

NS_ASSUME_NONNULL_END
