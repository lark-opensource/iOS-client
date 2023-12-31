//
//  HMDUploadHelper.h
//  Heimdallr
//
//  Created by fengyadong on 2018/3/8.
//

#import <Foundation/Foundation.h>

@interface HMDUploadHelper : NSObject

+ (nonnull instancetype)sharedInstance;

- (nonnull NSDictionary *)headerInfo;

- (nonnull NSDictionary *) infrequentChangeHeaderParam;

- (nonnull NSDictionary *) constantHeaderParam;

@end

