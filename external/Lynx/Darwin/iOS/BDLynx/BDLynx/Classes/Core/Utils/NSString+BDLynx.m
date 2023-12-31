//
//  NSString+BDLynx.m
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/5/15.
//

#import "NSString+BDLynx.h"

@implementation NSString (BDLynx)

- (NSString *)BDLynx_scheme {
  NSArray<NSString *> *urlComponents = [self componentsSeparatedByString:@"://"];

  if (BTD_isEmptyArray(urlComponents) || BTD_isEmptyString(urlComponents.firstObject)) {
    return nil;
  }

  return urlComponents.firstObject;
}

- (NSString *)BDLynx_path {
  NSArray<NSString *> *urlComponents = [self componentsSeparatedByString:@"://"];
  if (!urlComponents || urlComponents.count < 2 || BTD_isEmptyString(urlComponents[1])) {
    return nil;
  }

  urlComponents = [urlComponents[1] componentsSeparatedByString:@"?"];
  return urlComponents[0];
}

- (NSArray<NSString *> *)BDLynx_pathComponentArray {
  NSString *path = [self BDLynx_path];
  if ([path hasSuffix:@"/"]) {
    path = [path substringToIndex:([path length] - 1)];
  }

  if (BTD_isEmptyString(path)) {
    return nil;
  }

  NSMutableArray<NSString *> *resultPathComponentArray = [NSMutableArray new];
  NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
  for (NSString *pathItem in pathComponents) {
    [resultPathComponentArray addObject:pathItem];
  }

  return resultPathComponentArray;
}

- (NSString *)BDLynx_queryString {
  NSArray<NSString *> *urlComponents = [self componentsSeparatedByString:@"?"];
  if (!urlComponents || urlComponents.count < 2 || BTD_isEmptyString(urlComponents[1])) {
    return nil;
  }

  return urlComponents[1];
}

- (NSDictionary<NSString *, NSString *> *)BDLynx_queryDictWithEscapes:(BOOL)escapes {
  NSString *queryString = [self BDLynx_queryString];

  NSMutableDictionary<NSString *, NSString *> *queryDict = [NSMutableDictionary new];
  NSArray<NSString *> *queryArray = [queryString componentsSeparatedByString:@"&"];
  for (NSString *queryItem in queryArray) {
    NSArray<NSString *> *pair = [queryItem componentsSeparatedByString:@"="];
    if (!pair || pair.count < 2 || BTD_isEmptyString(pair[0]) || BTD_isEmptyString(pair[1])) {
      NSRange range = [queryItem rangeOfString:@"=" options:NSLiteralSearch];
      if (range.location != NSNotFound) {
        NSString *keyString = [queryItem substringToIndex:range.location];
        NSString *valueString = [queryItem substringFromIndex:(range.location + range.length)];
        if (!BTD_isEmptyString(keyString) && !BTD_isEmptyString(valueString)) {
          pair = @[ keyString, valueString ];
        } else {
          continue;
        }
      } else {
        continue;
      }
    }

    NSString *keyString = nil, *valueString = nil;
    if (escapes) {
      keyString = [pair[0] BDLynx_stringByReplacingPercentEscapes];
      valueString = [pair[1] BDLynx_stringByReplacingPercentEscapes];
    } else {
      keyString = pair[0];
      valueString = pair[1];
    }
    if (!BTD_isEmptyString(keyString) && !BTD_isEmptyString(valueString)) {
      [queryDict setObject:valueString forKey:keyString];
    }
  }

  if (queryDict.count == 0) {
    queryDict = nil;
  }

  return queryDict;
}

- (NSString *)BDLynx_stringByReplacingPercentEscapes {
  return [self stringByRemovingPercentEncoding];
}

@end
