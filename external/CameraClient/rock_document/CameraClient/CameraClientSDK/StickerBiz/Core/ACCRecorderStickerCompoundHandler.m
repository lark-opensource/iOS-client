//
//  ACCRecorderStickerCompoundHandler.m
//  Indexer
//
//  Created by Daniel on 2021/8/24.
//

#import "ACCRecorderStickerCompoundHandler.h"
#import "ACCStickerHandler+Private.h"

#import <CreativeKit/ACCMacros.h>

@implementation ACCRecorderStickerCompoundHandler

#pragma mark - Getters

- (ACCStickerContainerView *)stickerContainerView
{
    ACCStickerContainerView *stickerContainerView = ACCBLOCK_INVOKE(self.stickerContainerLoader);
    if (stickerContainerView == nil) {
        stickerContainerView = [super stickerContainerView];
    }
    return stickerContainerView;
}

@end
