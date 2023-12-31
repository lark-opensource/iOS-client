//
//  BDXBridgeCustomValueTransformer.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MTLValueTransformer;

@interface BDXBridgeCustomValueTransformer : NSObject

+ (MTLValueTransformer *)enumTransformerWithDictionary:(NSDictionary<NSString *, NSNumber *> *)dictionary;
+ (MTLValueTransformer *)optionsTransformerWithDictionary:(NSDictionary<NSString *, NSNumber *> *)dictionary;
+ (MTLValueTransformer *)colorTransformer;

@end

NS_ASSUME_NONNULL_END
