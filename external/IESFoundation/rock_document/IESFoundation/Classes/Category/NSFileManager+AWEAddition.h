//
//  NSFileManager+AWEAddition.h
//  Aweme
//
//  Created by 旭旭 on 2018/1/29.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (AWEAddition)

- (NSArray<NSString *> *)awe_allDirsInPath:(NSString *)path;

@end
