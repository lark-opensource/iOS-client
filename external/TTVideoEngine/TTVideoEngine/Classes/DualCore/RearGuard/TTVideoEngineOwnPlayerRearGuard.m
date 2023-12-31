//
// TTVideoEngineOwnPlayerRearGuard.m
// TTVideoEngine
//
// Created by baishuai on 2020/11/29
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineOwnPlayerRearGuard.h"

@implementation TTPlayerRearGuardFactory

- (NSObject<TTAVPlayerItemProtocol> *)playerItemWithURL:(NSURL *)url {
    return nil;
}

- (NSObject<TTAVPlayerProtocol> *)playerWithItem:(NSObject<TTAVPlayerItemProtocol>*)item options:(NSDictionary *)header {
    return nil;
}

- (UIView<TTPlayerViewProtocol> *)viewWithFrame:(CGRect)frame {
    return nil;
}

- (NSString *) getVersion {
    return nil;
}

@end
