//
//  HTSMD5.h
//  Pods
//
//  Created by Gavin on 2017/2/15.
//
//
#import <Foundation/Foundation.h>

@interface TMAMD5 : NSObject

+ (NSString *)getMD5withURL:(NSURL *)fileURL;
+ (NSString *)getMD5withPath:(NSString *)filePath;

@end


