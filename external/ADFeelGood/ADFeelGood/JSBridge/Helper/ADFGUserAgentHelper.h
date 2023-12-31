//
//  ADFGUserAgentHelper.h
//  BUAdSDK
//
//  Created by cuiyanan on 2019/9/3.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADFGUserAgentHelper : NSObject
+ (instancetype)sharedInstance;

- (NSString *)setup;

- (NSString *)userAgent;
@end

