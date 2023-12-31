//
//  BulletXWebKitApi.m
//  BulletWebKit
//
//  Created by bill on 2020/2/6.
//

#import "BDXWebKitApi.h"
#import <BDXServiceCenter/BDXContext.h>
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXWebKitProtocol.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>

@implementation BDXWebKitApi

- (UIView<BDXKitViewProtocol> *)provideKitViewWithURL:(NSURL *)url
{
    NSString *bid = [self.context getObjForKey:kBDXContextKeyBid];
    id<BDXWebKitProtocol> webKitService = BDXSERVICE_WITH_DEFAULT(BDXWebKitProtocol, bid);
    if (!webKitService) {
        return nil;
    }

    NSURL *resolvedURL = nil;
    if ([url.scheme containsString:@"webview"]) {
        NSString *urlString = [url btd_queryItemsWithDecoding][@"url"];
        resolvedURL = [NSURL URLWithString:urlString];
    } else if ([url.scheme containsString:@"http"]) {
        resolvedURL = url;
    }

    CGFloat frameWidth = [[self.context getObjForKey:@"__kit_frame_width"] doubleValue];
    CGFloat frameHeight = [[self.context getObjForKey:@"__kit_frame_height"] doubleValue];
    CGRect outerFrame = CGRectMake(0, 0, frameWidth, frameHeight);

    Class bridgeClass = [self.context getObjForKey:kBDXContextKeyBridgeClass];

    BDXSchemaParam *schemaParams = [self.context getObjForKey:kBDXContextKeySchemaParams];
    NSDictionary *extraParams = schemaParams.extra;
    
    BDXWebKitParams *params = [BDXWebKitParams new];
    params.context = self.context;
    params.bridgeClass = bridgeClass;
    params.enableSecureLink = [extraParams btd_boolValueForKey:@"enable_securelink" default:NO];

    UIView<BDXWebViewProtocol> *kitView = [webKitService createViewWithFrame:outerFrame params:params url:resolvedURL];
    return kitView;
}

@end
