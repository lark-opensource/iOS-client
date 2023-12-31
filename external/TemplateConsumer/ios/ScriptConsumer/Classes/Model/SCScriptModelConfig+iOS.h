//
//   SCScriptModelConfig+iOS.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/6/29.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <NLEPlatform/NLENode+iOS.h>
#import <NLEPlatform/NLEResourceNode+iOS.h>
#import <NLEPlatform/NLEStyleText+iOS.h>
NS_ASSUME_NONNULL_BEGIN


//RATIO_16_9 = 1,
//RATIO_1_1 = 2,
//RATIO_3_4 = 3,
//RATIO_4_3 = 4,
//RATIO_9_16 = 5

typedef enum : NSUInteger {
    SCScriptCanvasRatio_RATIO_16_9 = 1,
    SCScriptCanvasRatio_RATIO_1_1 = 2,
    SCScriptCanvasRatio_RATIO_3_4 = 3,
    SCScriptCanvasRatio_RATIO_4_3 = 4,
    SCScriptCanvasRatio_RATIO_9_16 = 5
} SCScriptCanvasRatio;

@interface SCScriptModelConfig_OC : NLENode_OC

@property(nonatomic,assign)SCScriptCanvasRatio canvasRatio;

@property(nonatomic,strong)NLEStyleText_OC *style;



@end

NS_ASSUME_NONNULL_END
