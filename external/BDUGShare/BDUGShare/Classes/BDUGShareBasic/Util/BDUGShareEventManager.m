//
//  BDUGShareEventManager.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/10/28.
//

#import "BDUGShareEventManager.h"

@implementation BDUGShareEventManager

BDUGShareEventManagerCommonParamsBlock __commonParamBlock;

+ (void)setCommonParamsblock:(BDUGShareEventManagerCommonParamsBlock)commonParamBlock {
    __commonParamBlock = commonParamBlock;
}

#pragma mark - tracker 埋点事件

+ (void)event:(NSString *)event params:(NSDictionary * _Nullable)params
{
    //拼接公参。
    NSMutableDictionary *resultParam = [[NSMutableDictionary alloc] init];
    if (__commonParamBlock) {
        NSDictionary *dict = __commonParamBlock();
        if (dict) {
            [resultParam addEntriesFromDictionary:dict] ;
        }
    }
    [resultParam addEntriesFromDictionary:params];
    [BDUGTracker event:event params:resultParam];
}

#pragma mark - monitor 监控事件

+ (void)trackService:(NSString *)serviceName attributes:(NSDictionary *)attributes
{
    //拼接公参。
    [self trackService:serviceName metric:nil category:attributes extra:nil];
}

+ (void)trackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue
{
    //拼接公参。
    NSMutableDictionary *resultParam = [[NSMutableDictionary alloc] init];
    if (__commonParamBlock) {
        NSDictionary *dict = __commonParamBlock();
        if (dict) {
            [resultParam addEntriesFromDictionary:dict] ;
        }
    }
    [resultParam addEntriesFromDictionary:category];
    if ([resultParam objectForKey:@"status"]) {
        NSMutableDictionary *extraDict = [[NSMutableDictionary alloc] init];
        [extraDict setObject:resultParam[@"status"] forKey:@"status"];
        [resultParam removeObjectForKey:@"status"];
        [extraDict setObject:resultParam forKey:@"category"];
        [BDUGMonitor trackService:serviceName value:nil extra:extraDict];
    } else {
        [BDUGMonitor trackService:serviceName metric:metric category:resultParam extra:extraValue];
    }
}

@end
