//
//  HTSVideoData+AWEPersistent.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/8/8.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <TTVideoEditor/HTSVideoData.h>

@interface HTSVideoData (AWEPersistent)

+ (NSDictionary *)readDictionaryFromPath:(NSString *)path error:(NSError *__autoreleasing*)error;

+ (BOOL)saveDictionaryToPath:(NSString *)path dict:(NSDictionary *) dict error:(NSError *__autoreleasing*)error;

/**
 *  持久化数据
 */
- (void)saveVideoDataToFileUsePropertyListSerialization:(NSString *_Nullable)filePath
                                             completion:(nullable void(^)(BOOL saved, NSError * _Nullable error))completion;

/**
 *  读取持久化数据（按保存时间从早到晚排序）
 */
+ (void)loadVideoDataFromFile:(NSString *_Nullable)filePath
                   completion:(nullable void (^)(HTSVideoData *_Nullable videoData, NSError *_Nullable error))completion;

@end
