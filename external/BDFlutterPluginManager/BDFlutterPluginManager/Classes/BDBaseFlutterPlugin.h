//
//  BDBaseFlutterPlugin.h
//  BDBaseFlutterPlugin
//
//  Created by 林一一 on 2019/9/16.
//

#import <Foundation/Foundation.h>
#import "BDBaseFlutterPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDBaseFlutterPlugin : NSObject

- (NSMutableDictionary *)createStandardSuccessResWithInfos:(NSDictionary * _Nullable)infos;
- (NSMutableDictionary *)createStandardFailResWithError:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
