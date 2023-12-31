//
//  MTLJSONAdapter+IESValueTransformers.h
//  IESVideoDetector
//
//  Created by geekxing on 2020/6/2.
//

#import <Mantle/Mantle.h>

@interface MTLJSONAdapter (IESValueTransformers)

+ (NSValueTransformer *)CMTimeJSONValueTransformer;
+ (NSValueTransformer *)CMTimeRangeJSONValueTransformer;

+ (NSValueTransformer<MTLTransformerErrorHandling> *)traverseArrayTransformerWithModelClass:(Class)modelClass;

+ (NSValueTransformer<MTLTransformerErrorHandling> *)traverseArrayTransformerWithModelClass:(Class)modelClass valueNodeForwardBlock:(MTLValueTransformerBlock)forwardBlock reverseBlock:(MTLValueTransformerBlock)reverseBlock;

+ (NSValueTransformer<MTLTransformerErrorHandling> *)traverseDictionaryTransformerWithModelClass:(Class)modelClass valueNodeForwardBlock:(MTLValueTransformerBlock)forwardBlock reverseBlock:(MTLValueTransformerBlock)reverseBlock ;

@end
