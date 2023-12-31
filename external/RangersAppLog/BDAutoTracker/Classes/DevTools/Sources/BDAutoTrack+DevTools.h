//
//  BDAutoTrack+DevTools.h
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/29/22.
//

#import "BDAutoTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrack (DevTools)

- (NSDictionary *)devtools_configToDictionary;

- (NSDictionary *)devtools_customHeaderToDictionary;

- (NSDictionary *)devtools_logsettings;

- (NSDictionary *)devtools_identifier;


@end

NS_ASSUME_NONNULL_END
