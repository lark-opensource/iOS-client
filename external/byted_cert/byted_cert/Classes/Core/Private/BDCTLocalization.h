//
//  BytedLiveLocalization.h
//  BytedLiveLocalization
//
//  Created by LiuChundian on 2019/3/22.
//  Copyright © 2019年 Liuchundian. All rights reserved.

#import <Foundation/Foundation.h>

#define BytedCertLocalizedString(key) \
    [BDCTLocalization.sharedInstance localString:key]


@interface BDCTLocalization : NSObject

+ (instancetype)sharedInstance;

- (void)setLanguage:(NSString *)language;

- (NSString *)getLanguage;

- (NSString *)localString:(NSString *)key;

@end
