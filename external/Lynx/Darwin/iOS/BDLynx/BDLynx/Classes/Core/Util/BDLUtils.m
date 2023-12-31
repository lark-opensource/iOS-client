//
//  BDLUtils.m
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import "BDLUtils.h"
#import <BDALog/BDAgileLog.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import "BDLSDKManager.h"
#import "BDLUtilProtocol.h"

@implementation BDLUtils

/**
 * alog输出信息
 */
+ (void)info:(NSString *)info {
  BDALOG_INFO_TAG(@"lynx", @"%@", info);
}

+ (void)warn:(NSString *)warn {
  BDALOG_WARN_TAG(@"lynx", @"%@", warn);
}

+ (void)error:(NSString *)error {
  BDALOG_ERROR_TAG(@"lynx", @"%@", error);
}

+ (void)fatal:(NSString *)fatal {
  BDALOG_FATAL_TAG(@"lynx", @"%@", fatal);
}

+ (void)reportLog:(NSString *)message {
  [BDL_SERVICE_WITH_SELECTOR(BDLUtilProtocol, @selector(keyLog:)) keyLog:message];
}

+ (void)logToSystem:(NSNumber *)isOpen {
  alog_set_console_log([isOpen boolValue]);
}

/**
 *  Sladar 监控
 *  监控某个service的值，并上报
 *  @param serviceName 埋点
 *  @param value 是一个float类型的，不可枚举
 *  @param extraValue 额外信息，方便追查问题使用
 */
+ (void)trackService:(NSString *)serviceName value:(float)value extra:(NSDictionary *)extraValue {
  [BDL_SERVICE_WITH_SELECTOR(BDLUtilProtocol, @selector(trackService:value:extra:))
      trackService:serviceName
             value:value
             extra:extraValue];
}

+ (void)trackData:(NSDictionary *)data logTypeStr:(NSString *)type {
  [BDL_SERVICE_WITH_SELECTOR(BDLUtilProtocol, @selector(trackData:logTypeStr:)) trackData:data
                                                                               logTypeStr:type];
}

/**
 * 埋点上报
 * @param eventName 埋点名
 * @param params 自定义参数
 */
+ (void)event:(NSString *)eventName params:(NSDictionary *)params {
  [BDL_SERVICE_WITH_SELECTOR(BDLUtilProtocol, @selector(event:params:)) event:eventName
                                                                       params:params];
}

+ (void)openSchema:(NSString *)schema {
  [BDL_SERVICE_WITH_SELECTOR(BDLUtilProtocol, @selector(openSchema:)) openSchema:schema];
}

+ (NSString *)bdl_md5StringOfString:(NSString *)source {
  NSData *sourceData = [source dataUsingEncoding:NSUTF8StringEncoding];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(sourceData.bytes, (CC_LONG)sourceData.length, result);
  return [NSString
      stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                       result[0], result[1], result[2], result[3], result[4], result[5], result[6],
                       result[7], result[8], result[9], result[10], result[11], result[12],
                       result[13], result[14], result[15]];
}
@end

BOOL BDLIsEmptyArray(NSArray *array) {
  return (!array || ![array isKindOfClass:[NSArray class]] || array.count == 0);
}

BOOL BDLIsEmptyString(NSString *string) {
  return (!string || ![string isKindOfClass:[NSString class]] || string.length == 0);
}

BOOL BDLIsEmptyDictionary(NSDictionary *dict) {
  return (!dict || ![dict isKindOfClass:[NSDictionary class]] || ((NSDictionary *)dict).count == 0);
}

NSArray *BDLSafeArray(NSArray *array) {
  return [array isKindOfClass:[NSArray class]] ? array : @[];
}

NSString *BDLSafeString(NSString *string) {
  return [string isKindOfClass:[NSString class]] ? string : @"";
}

NSDictionary *BDLSafeDictionary(NSDictionary *dict) {
  return [dict isKindOfClass:[NSDictionary class]] ? dict : @{};
}
