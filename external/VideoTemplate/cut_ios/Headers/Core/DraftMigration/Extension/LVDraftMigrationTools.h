//
//  LVDraftMigrationTools.h
//  BDABTestSDK
//
//  Created by kevin gao on 9/26/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVDraftMigrationTools : NSObject

#pragma mark - 数据转换

/*
 JSON字符串转化为字典
 */
+ (NSDictionary * _Nullable)dictionaryWithJsonString:(NSString *)jsonString;

/*
 字典转json字符串方法
 */
+ (NSString * _Nullable)convertToJsonData:(NSDictionary *)dict;

/*
 字典转data
 */
+ (NSData* _Nullable)dictToData:(NSDictionary *)dict;

/*
 data转字典
 */
+ (NSDictionary * _Nullable)dataToDict:(NSData*)data;

#pragma mark - 时间转换

+ (NSTimeInterval)currentTime;

+ (NSString*)currentTimeString;

+ (NSString*)currentTimeWith:(NSTimeInterval)time;

+ (NSString*)dateToString:(NSDate*)date;

#pragma mark - 字典转换

+ (NSMutableDictionary *)recursiveToMutable:(id)object;

@end

NS_ASSUME_NONNULL_END
