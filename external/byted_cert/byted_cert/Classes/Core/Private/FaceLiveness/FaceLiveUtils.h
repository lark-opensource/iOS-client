//
//  FaceLiveUtils.h
//  BytedCertIOS
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#ifndef FaceLiveUtils_h
#define FaceLiveUtils_h


@interface FaceLiveUtils : NSObject

+ (NSString *)getResource:(NSString *)module resName:(NSString *)resName;

+ (NSData *)convertRawBufferToImage:(unsigned char *)rawData
                          imageName:(NSString *)imageName
                               cols:(int)cols
                               rows:(int)rows
                          saveImage:(bool)saveImage;

+ (NSData *)convertRawBufferToImage:(unsigned char *)rawData
                          imageName:(NSString *)imageName
                               cols:(int)cols
                               rows:(int)rows
                          bgra2rgba:(bool)bgra2rgba
                          saveImage:(bool)saveImage;

+ (NSArray *)sortedRandomArrayByArray:(NSArray *)array;

+ (NSString *)packData:(NSString *)dataString newCryptType:(BOOL *)newCryptType;

+ (NSData *)buildFaceCompareSDKDataWithParams:(NSDictionary *)params;

+ (NSString *)smashLiveModelName;

+ (NSString *)smashSdkVersion;

@end

#endif /* FaceLiveUtils_h */
