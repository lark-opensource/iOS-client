//
//  BDPPluginBase.h
//  Timor
//
//  Created by CsoWhy on 2018/10/20.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUtils.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPBootstrapHeader.h>
#define kBDPH5WebViewFrameID @"frameId"
@interface BDPPluginBase : BDPJSBridgeInstancePlugin

+ (NSString *)resultMsgOfCheckHasKeys:(NSArray<NSString*>*)nameArr inParameters:(NSDictionary*)paramDic;
+ (BOOL)isParamValid:(BDPJSBridgeCallback)callback paramDic:(NSDictionary *)paramDic paramArr:(NSArray *)paramArr;
/// 根据 checkKeys 检查 paramDic 中的数据是否合法
/// @param paramDic 被检查的参数表
/// @param checkKeys 需要检查的字段
/// @return 返回异常errMsg，没有异常返回 nil，
+ (NSString *)isParamValid:(NSDictionary *)paramDic withCheckKeys:(NSArray *)checkKeys;
@end
