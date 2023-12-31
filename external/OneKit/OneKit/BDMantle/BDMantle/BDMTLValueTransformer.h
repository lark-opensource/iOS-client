//
//  BDMTLValueTransformer.h
//  BDMantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BDMTLTransformerErrorHandling.h"

/// A block that represents a transformation.
///
/// value   - The value to transform.
/// success - The block must set this parameter to indicate whether the
///           transformation was successful.
///           BDMTLValueTransformer will always call this block with *success
///           initialized to YES.
/// error   - If not NULL, this may be set to an error that occurs during
///           transforming the value.
///
/// Returns the result of the transformation, which may be nil.
typedef id (^BDMTLValueTransformerBlock)(id value, BOOL *success, NSError **error);

///
/// A value transformer supporting block-based transformation.
///
@interface BDMTLValueTransformer : NSValueTransformer <BDMTLTransformerErrorHandling>

/// Returns a transformer which transforms values using the given block. Reverse
/// transformations will not be allowed.
+ (instancetype)transformerUsingForwardBlock:(BDMTLValueTransformerBlock)transformation;

/// Returns a transformer which transforms values using the given block, for
/// forward or reverse transformations.
+ (instancetype)transformerUsingReversibleBlock:(BDMTLValueTransformerBlock)transformation;

/// Returns a transformer which transforms values using the given blocks.
+ (instancetype)transformerUsingForwardBlock:(BDMTLValueTransformerBlock)forwardTransformation reverseBlock:(BDMTLValueTransformerBlock)reverseTransformation;

@end

@interface BDMTLValueTransformer (Deprecated)

+ (NSValueTransformer *)transformerWithBlock:(id (^)(id))transformationBlock __attribute__((deprecated("Replaced by +transformerUsingForwardBlock:")));

+ (NSValueTransformer *)reversibleTransformerWithBlock:(id (^)(id))transformationBlock __attribute__((deprecated("Replaced by +transformerUsingReversibleBlock:")));

+ (NSValueTransformer *)reversibleTransformerWithForwardBlock:(id (^)(id))forwardBlock reverseBlock:(id (^)(id))reverseBlock __attribute__((deprecated("Replaced by +transformerUsingForwardBlock:reverseBlock:")));

@end
