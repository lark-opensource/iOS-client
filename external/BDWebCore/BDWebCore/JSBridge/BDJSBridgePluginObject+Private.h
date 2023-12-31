//
//  BDJSBridgePluginObject+Private.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/20.
//
#import "BDJSBridgePluginObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDJSBridgePluginObject (Private)

@property(nonatomic, strong) NSMutableDictionary<NSString *, id> *protocols;

@end

NS_ASSUME_NONNULL_END
