//
//  TMAWebkitResourceManager.h
//  WebkitResource
//
//  Created by 殷源 on 2018/9/20.
//  Copyright © 2018 britayin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TMAWebkitResourceManager : NSObject

+ (instancetype)defaultManager;

- (NSString *)resourcePathForURL:(NSURL *)url pageURL:(NSURL *)pageURL;
- (UIImage *)imageResourceForURL:(NSURL *)url pageURL:(NSURL *)pageURL;

@end
