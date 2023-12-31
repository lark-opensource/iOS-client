//
//  AWEAlbumFaceModel.m
//  AWEStudio
//
//  Created by liubing on 2018/5/25.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEAlbumImageModel.h"

@implementation AWEAlbumImageModel

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[AWEAlbumImageModel class]]) {
        return NO;
    }
    
    return [self.assetLocalIdentifier isEqual:((AWEAlbumImageModel *)object).assetLocalIdentifier];
}

- (NSUInteger)hash
{
    return [self.assetLocalIdentifier hash];
}

@end
