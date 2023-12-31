//
//  BDAutoTrackerALinkPasteBoardParser.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const s_pb_DemandPrefix = @"datatracer:";

@interface BDAutoTrackerALinkPasteBoardParser : NSObject

@property (nonatomic, readonly) NSString *allQueryString;

- (instancetype)initWithPasteBoardItem:(NSString *)pbItem;

/// https://bytedance.feishu.cn/docs/doccnUAnJ4crD9RCYPHuzUPujxh#
- (NSString* )ab_version;

- (NSString* )tr_web_ssid;


@end

NS_ASSUME_NONNULL_END
