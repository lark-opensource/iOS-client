//
//  NSString+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2021 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (DVE)

- (NSDictionary *)dve_toDic;

/// 返回路径的名称
- (NSString *)dve_pathName;
/// 返回路径的小写名称
- (NSString *)dve_lowercasePathName;

+ (NSString *)dve_timeFormatWithTimeInterval:(NSTimeInterval)duration;

/// 按照传入的时间格式，返回当前的日期
/// @param format 时间格式
+ (NSString *)dve_curDateStringWithFormatter:(NSString *)format;

/// 返回日期（格式为 年份-月份-日 小时(24小时制):分钟:秒）[自动补零]
+ (NSString *)dve_curTimeString;

/// 返回日期（格式为 年份-月份-日） [自动补零]
+ (NSString *)dve_curDateString;

- (NSString *)dve_pathInBundle:(NSString *)bundleName;

+ (NSString *)dve_UUIDString;

- (NSString *)dve_md5String;

/// 计算文本占据的UI大小
/// @param font 文本字体
/// @param maxWidth 文本最大宽度
/// @param maxLine 文本最大行数限制
- (CGSize)dve_sizeWithFont:(UIFont *)font width:(CGFloat)maxWidth maxLine:(NSInteger)maxLine;

@end

NS_ASSUME_NONNULL_END
