//
//  ACCAlbumImageInformationStickerDataManager.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/20.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCAlbumImageInformationStickerDataManager.h"


@interface ACCAlbumImageInformationStickerDataManager ()

@end

@implementation ACCAlbumImageInformationStickerDataManager

- (instancetype)init
{
    if (self = [super init]) {
        self.pannelName = @"propsforpic";
    }
    
    return self;
}

+ (instancetype)defaultManager
{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

@end
