//
//  BDLynxParams.m
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/5/15.
//

#import "BDLynxParams.h"
#import "BDLynxView.h"

#import "NSDictionary+BDLynxAdditions.h"
#import "NSString+BDLynx.h"

@implementation BDLynxParams

+ (BDLynxViewBaseParams *)getBaseParam:(NSString *)schema {
  NSDictionary *paramDict = [schema BDLynx_queryDictWithEscapes:YES];
  NSString *channelName = @"";
  if (paramDict[@"channel"]) {
    channelName = [paramDict bdlynx_stringValueForKey:@"channel"] ?: @"";
  }
  NSString *bundleName = @"";
  if (paramDict[@"bundle"]) {
    bundleName = [paramDict bdlynx_stringValueForKey:@"bundle"] ?: @"";
  }
  NSInteger isDynamic = 0;
  if (paramDict[@"dynamic"]) {
    isDynamic = [paramDict bdlynx_integerValueForKey:@"dynamic"];
  }
  NSString *group = @"";
  if (paramDict[@"group"]) {
    group = [paramDict bdlynx_stringValueForKey:@"group"] ?: @"";
  }
  NSString *sourceUrl;
  if (paramDict[@"surl"] || paramDict[@"url"]) {
    sourceUrl = ([paramDict bdlynx_stringValueForKey:@"surl"]
                     ?: [paramDict bdlynx_stringValueForKey:@"url"])
                    ?: @"";
  }
  NSString *fallbackURL;
  if (paramDict[@"fallback_url"]) {
    fallbackURL = [paramDict bdlynx_stringValueForKey:@"fallback_url"] ?: @"";
  }
  BOOL forceH5 = NO;
  if (paramDict[@"force_h5"]) {
    forceH5 = [paramDict bdlynx_boolValueForKey:@"force_h5"];
  }

  BOOL disableShare = ![paramDict bdlynx_boolValueForKey:@"share_group"];

  BDLynxViewBaseParams *params = [[BDLynxViewBaseParams alloc] init];
  params.channel = channelName;
  params.bundle = bundleName;
  if (!BTD_isEmptyString(group)) {
    params.groupContext = group;
  }
  params.dynamic = isDynamic;
  if (!BTD_isEmptyString(sourceUrl)) {
    params.sourceUrl = sourceUrl;
  }
  params.disableShare = disableShare;
  params.initialProperties = paramDict ?: @{};
  if (!BTD_isEmptyString(fallbackURL)) {
    params.fallbackURL = [NSURL URLWithString:fallbackURL ?: @""];
  }
  params.forceFallback = forceH5 ? BDLynxForceFallbackTypeH5 : BDLynxForceFallbackTypeUndefined;
  return params;
}

@end
