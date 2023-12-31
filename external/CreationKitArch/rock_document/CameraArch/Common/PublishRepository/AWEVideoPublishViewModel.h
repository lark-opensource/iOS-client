//
//  AWEVideoPublishViewModel.h
//  Aweme
//
//  Created by Quan Quan on 16/8/28.
//  Copyright  ©  2016 byedance. All rights reserved
//

#import <Foundation/Foundation.h>
#import "ACCRepositoryWrapper.h"

#define ASSERT_IN_SUB_CLASS \
NSAssert(NO, @"should implementation in sub class");

@interface AWEVideoPublishSourceInfo : NSObject
// Store data in "description" in metadata
@property (nonatomic, strong) NSDictionary *descriptionInfo;
- (NSDictionary *)jsonInfo;
- (instancetype)initWithDictionary:(NSDictionary *)dic;
@end

@interface AWEVideoPublishAwemeInfo : NSObject
@property (nonatomic, copy) NSString *itemID;
@property (nonatomic, copy) NSString *originalVid;
@property (nonatomic, copy) NSString *musicInfo;

@end

@interface AWEVideoPublishViewModel : ACCRepositoryWrapper

#pragma mark - basic info

@property (nonatomic, strong) AWEVideoPublishAwemeInfo *awemeInfo;

+ (NSString *)createIDWithTaskID:(NSString *)taskID deviceID:(NSString *)deviceID UUID:(NSString *)UUID;

- (void)copyPublishModelFrom:(AWEVideoPublishViewModel *)from;

+ (void)shadowCopyPublishViewModelTo:(AWEVideoPublishViewModel *)to from:(AWEVideoPublishViewModel *)from;

@end
