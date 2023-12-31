//
//  KAIntialize.m
//  LarkMessengerDemo
//
//  Created by Supeng on 2021/10/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
@import KAFileInterface;
#import "DemoFilePreviewer.h"

@interface LarkKAFileRegistry : NSObject
+(NSArray<FilePreviewer>*)registeredFilePreviewers;
@end

@implementation LarkKAFileRegistry

+(NSArray<FilePreviewer>*)registeredFilePreviewers {
    return (NSArray<FilePreviewer>*)@[[[DemoFilePreviewer alloc] init]];
}

@end
