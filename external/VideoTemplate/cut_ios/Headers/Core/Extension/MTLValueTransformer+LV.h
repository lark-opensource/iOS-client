//
//  MTLValueTransformer+CMTime.h
//  longVideo
//
//  Created by xiongzhuang on 2019/7/18.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTLValueTransformer (LV)

/**
 CMTime的解析
 */
+ (NSValueTransformer *)lv_CMTimeJSONTransformer;

/**
 CMTimeRange的解析
 */
+ (NSValueTransformer *)lv_CMTimeRangeJSONTransformer;


/**
 CGPoint的解析
 */
+ (NSValueTransformer *)lv_pointJSONTransformer;


///**
// 资源类型的解析
// */
//+ (NSValueTransformer *)lv_realTypeJSONTransformer;
//
//+ (NSDictionary<NSString *, NSNumber *> *)lv_realTypeMapper;

@end

NS_ASSUME_NONNULL_END
