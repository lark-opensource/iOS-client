//
//  NSData+BDBCAdditions.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2020/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSData (BDCERTAdditions)

/// 将图片的metadata信息（exif等）写入到图片流
+ (NSData *)bdct_saveImageWithImageData:(NSData *)data properties:(NSDictionary *)properties;

- (NSDictionary *)bdct_imageMetaData;

@end

NS_ASSUME_NONNULL_END
