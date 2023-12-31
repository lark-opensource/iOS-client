//
//  BDPTimorLaunchParam.m
//  Timor
//
//  Created by MacPu on 2019/11/28.
//

#import "BDPTimorLaunchParam.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/NSData+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

NSString *const kRealMachineDebugAddressKey = @"realMachineDebugAddress";
NSString *const kTargetWindowKey = @"targetWindow";

@interface BDPTimorLaunchVdomParam ()

@property (nonatomic, copy, readwrite) NSString *vdom;
@property (nonatomic, copy, readwrite) NSString *css;
@property (nonatomic, copy, readwrite) NSDictionary *config;
@property (nonatomic, assign, readwrite) int64_t version_code;

@end

@implementation BDPTimorLaunchVdomParam

@end

@implementation BDPTimorLaunchExtraParma

- (instancetype)initWithExtra:(NSDictionary *)extra
{
    if (self = [super init]) {
        _realMachineDebugAddress = [extra bdp_stringValueForKey:kRealMachineDebugAddressKey].copy;
        _window = [extra bdp_objectForKey:kTargetWindowKey ofClass:UIWindow.class];
    }
    return self;
}

@end

#pragma mark --
#pragma mark -- BDPTimorLaunchParam


@implementation BDPTimorLaunchParam

- (void)updateWithSnapshot:(NSString *)snapshot
{
    NSDictionary *vdomRenderInfo = [snapshot JSONValue];
    if (!BDPIsEmptyDictionary(vdomRenderInfo)) {
        // 如果有vdom参数,先验证vdom的可靠性.
        NSString *base64VDOM = [vdomRenderInfo bdp_stringValueForKey:@"vdom"];
        NSString *base64CSS = [vdomRenderInfo bdp_stringValueForKey:@"css"];
        NSString *configStr = [vdomRenderInfo bdp_stringValueForKey:@"config"];
        if (!BDPIsEmptyString(base64VDOM) && !BDPIsEmptyString(base64CSS) && !BDPIsEmptyString(configStr)) {
            // 解析vdom， 先base64 再 ungzip。
            NSData *vdomData = [[NSData alloc] initWithBase64EncodedString:base64VDOM options:0];
            NSData *cssData = [[NSData alloc] initWithBase64EncodedString:base64CSS options:0];
            NSString *vdom = [[NSString alloc] initWithData:[vdomData bdp_gunzippedData] encoding:NSUTF8StringEncoding];
            NSString *css = [[NSString alloc] initWithData:[cssData bdp_gunzippedData] encoding:NSUTF8StringEncoding];
            NSDictionary *config = [configStr JSONValue];
            if (!BDPIsEmptyString(vdom) && !BDPIsEmptyString(css) && !BDPIsEmptyDictionary(config)) {
                // 如果解析出来有数据，将vdom 传入TimorClient。
                self.vdom = @{@"vdom": vdom,
                              @"css": css,
                              @"config": config,
                              @"version_code":@([vdomRenderInfo bdp_intValueForKey:@"version_code"])};
            }
        }
    }
}

@end
