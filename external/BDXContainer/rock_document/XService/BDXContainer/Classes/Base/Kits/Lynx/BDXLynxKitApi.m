//
//  BDXLynxKitApi.m
//  BDXLynxKit
//
//  Created by bill on 2020/2/6.
//

#import "BDXLynxKitApi.h"
#import <BDXBridgeKit/BDXBridgeKit.h>
#import <BDXServiceCenter/BDXContext.h>
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXLynxKitProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>

@implementation BDXLynxKitApi

- (UIView<BDXKitViewProtocol> *)provideKitViewWithURL:(NSURL *)url
{
    NSString *bid = [self.context getObjForKey:kBDXContextKeyBid];
    id<BDXLynxKitProtocol> lynxKitService = BDXSERVICE_WITH_DEFAULT(BDXLynxKitProtocol, bid);
    if (!lynxKitService) {
        return nil;
    }

    BDXLynxKitParams *params = [self createLynxKitParamsWithContext:self.context];
    NSNumber *widthMode = [self.context getObjForKey:kBDXContextKeyWidthMode];
    NSNumber *heightMode = [self.context getObjForKey:kBDXContextKeyHeightMode];
    params.widthMode = widthMode ? [widthMode intValue] : BDXLynxViewSizeModeExact;
    params.heightMode = heightMode ? [heightMode intValue] : BDXLynxViewSizeModeExact;
    params.globalProps = [self.context getObjForKey:kBDXContextKeyGlobalProps];
    params.accessKey = [self.context getObjForKey:kBDXContextKeyAccessKey];

    params.context = self.context;
    CGFloat frameWidth = [[self.context getObjForKey:@"__kit_frame_width"] doubleValue];
    CGFloat frameHeight = [[self.context getObjForKey:@"__kit_frame_height"] doubleValue];

    CGRect outerFrame = CGRectMake(0, 0, frameWidth, frameHeight);
    UIView<BDXLynxViewProtocol> *kitView = [lynxKitService createViewWithFrame:outerFrame params:params];

    NSArray<id<BDXLynxElement>> *customUIElements = [self.context getObjForKey:kBDXContextKeyCustomUIElements];

    if (kitView) {
        for (id<BDXLynxElement> element in customUIElements) {
            Class elementClass = element.lynxElementClassName;
            NSString *elementName = element.lynxElementName;
            if (elementClass && !BTD_isEmptyString(elementName)) {
                [kitView registerUI:elementClass withName:elementName];
            }
        }
    }

    return kitView;
}

- (BDXLynxKitParams *)createLynxKitParamsWithContext:(BDXContext *)context
{
    BDXLynxKitParams *lynxKitParams = [[BDXLynxKitParams alloc] init];
    BDXSchemaParam *params = [context getObjForKey:kBDXContextKeySchemaParams];
    NSDictionary *extraParams = params.extra;
    lynxKitParams.sourceUrl = [extraParams btd_stringValueForKey:@"surl"];
    if(!lynxKitParams.sourceUrl){
        lynxKitParams.sourceUrl = [extraParams btd_stringValueForKey:@"url"];
    }
    if(!lynxKitParams.sourceUrl){
        lynxKitParams.sourceUrl = [extraParams btd_stringValueForKey:@"fallback_url"];
    }
    lynxKitParams.groupContext = [extraParams btd_stringValueForKey:@"group"];
    lynxKitParams.disableShare = [extraParams btd_boolValueForKey:@"disable_share" default:NO];
    lynxKitParams.enableCanvas = [extraParams btd_boolValueForKey:@"enable_canvas" default:NO];
    lynxKitParams.dynamic = [extraParams btd_integerValueForKey:@"dynamic" default:0];
    lynxKitParams.channel = [extraParams btd_stringValueForKey:@"channel"];
    lynxKitParams.bundle = [extraParams btd_stringValueForKey:@"bundle"];

    NSDictionary *initialData = [self.context getObjForKey:kBDXContextKeyInitialData];
    NSMutableDictionary *initialProps = [NSMutableDictionary dictionaryWithDictionary:initialData];

    NSString *dUrl = [extraParams btd_stringValueForKey:@"durl"];
    if (!BTD_isEmptyString(dUrl)) {
        NSData *durlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:dUrl]];
        if (durlData) {
            id JSONObject = [NSJSONSerialization JSONObjectWithData:durlData options:0 error:nil];
            if ([JSONObject isKindOfClass:NSDictionary.class]) {
                [initialProps addEntriesFromDictionary:(NSDictionary *)JSONObject];
            }
        }
    }

    if (initialData) {
        lynxKitParams.initialProperties = [initialProps copy];
    }
    lynxKitParams.initialPropertiesState = [self.context getObjForKey:kBDXContextKeyInitialDataMarkState];

    if (!lynxKitParams.localUrl) {
        lynxKitParams.localUrl = lynxKitParams.sourceUrl;
    }

    if (!lynxKitParams.localUrl) {
        lynxKitParams.localUrl = @"local";
    }

    lynxKitParams.disableBuildin = params.disableBuiltIn;
    lynxKitParams.disableGurd = params.disableGurd;

    lynxKitParams.queryItems = params.extra;
    lynxKitParams.context = context;

    return lynxKitParams;
}

@end
