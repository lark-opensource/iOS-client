//
//  MVPRecordFlowConfigProtocolImpl.m
//  MVP
//
//  Created by Liu Deping on 2020/12/30.
//

#import "MVPRecordFlowConfigProtocolImpl.h"

@implementation MVPRecordFlowConfigProtocolImpl

- (BOOL)enableLightningStyleRecordButton
{
    return YES;
}

- (BOOL)IMRecordIsInTapToTakePictureRecordMode
{
    return NO;
}

- (BOOL)needJumpDirectlyAfterTakePicture
{
    return YES;
}

- (BOOL)enableTapToTakePictureRecordMode:(BOOL)isStoryMode {
    return NO;
}


@end
