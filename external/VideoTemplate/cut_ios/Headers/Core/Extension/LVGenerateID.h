//
//  LVGenerateID.h
//  longVideo
//
//  Created by xiongzhuang on 2019/7/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVGenerateID : NSObject

/**
 生成唯一标识

 @return 唯一标识
 */
+ (NSString *)generate;


/**
 生成唯一标识

 @param prefix 前缀
 @return 唯一标识
 */
+ (NSString *)generateWithPrefix:(NSString *)prefix;

@end

NS_ASSUME_NONNULL_END
