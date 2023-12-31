//
//  BDCTCorePiperHandler+NFC.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/4/10.
//

#import "BDCTCorePiperHandler+NFC.h"
#import "BytedCertNFCReader.h"
#import <ByteDanceKit/ByteDanceKit.h>


@implementation BDCTCorePiperHandler (NFC)

- (void)registerStartNFC {
    [self registeJSBWithName:@"bytedcert.startNFC" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        BytedCertNFCReader *nfcReader = [[BytedCertNFCReader alloc] init];
        @weakify(self);
        void (^connectBlock)(JLConnectTagState connectState) = ^(JLConnectTagState connectState) {
            @strongify(self);
            [self.flow.performance nfcConnected];
            [self fireEvent:@"bytedcert.nfcReading" params:nil];
        };
        [nfcReader startNFCWithParams:params connectBlock:connectBlock completion:^(NSDictionary *_Nonnull nfcResult) {
            callback(TTBridgeMsgSuccess, nfcResult, nil);
            [self.flow.performance nfcEnd];
            [self fireEvent:@"bytedcert.nfcEnd" params:nfcResult];
        }];
    }];
}

- (void)registerStopNFC {
    [self registeJSBWithName:@"bytedcert.stopNFC" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        callback(TTBridgeMsgSuccess, nil, nil);
    }];
}
@end
