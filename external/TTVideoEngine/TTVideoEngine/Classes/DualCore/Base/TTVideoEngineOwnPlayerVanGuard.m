//
// TTVideoEngineOwnPlayerVanGuard.m
// TTVideoEngine
//
// Created by baishuai on 2020/11/29
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineOwnPlayerVanGuard.h"

#include <TTPlayerSDK/TTAVPlayerItem.h>
#include <TTPlayerSDK/TTAVPlayer.h>
#include <TTPlayerSDK/TTPlayerView.h>

@implementation TTPlayerVanGuardFactory

- (NSObject<TTAVPlayerProtocol> *)playerWithItem:(NSObject<TTAVPlayerItemProtocol>*)item options:(NSDictionary *)header {
    return [TTAVPlayer playerWithItem:item options:header];
}

- (NSObject<TTAVPlayerItemProtocol> *)playerItemWithURL:(NSURL *)url {
    return [TTAVPlayerItem playerItemWithURL:url];
}

- (UIView<TTPlayerViewProtocol> *)viewWithFrame:(CGRect)frame {
    return [[TTPlayerView alloc] initWithFrame:frame];
}

- (NSString *) getVersion {
    return [TTAVPlayer playerVersion];
}

@end


