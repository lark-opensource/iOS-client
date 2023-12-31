//
//  AWEVideoPublishViewModel+FilterEdit.m
//  Aweme
//
//  Created by Liu Bing on 5/11/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "AWERepoContextModel.h"
#import "AWEVideoPublishViewModel+FilterEdit.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <objc/message.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

@implementation AWEVideoPublishViewModel (FilterEdit)

- (NSDictionary *)videoFragmentInfoDictionary
{
    return [self.repoTrack videoFragmentInfoDictionary];
}

- (void)trackPostEvent:(NSString *)event enterMethod:(NSString *)enterMethod
{
    [self trackPostEvent:event enterMethod:enterMethod extraInfo:nil];
}

- (void)trackPostEvent:(NSString *)event enterMethod:(NSString *)enterMethod extraInfo:(NSDictionary *)extraInfo
{
    [self trackPostEvent:event enterMethod:enterMethod extraInfo:extraInfo isForceSend:NO];
}

- (void)trackPostEvent:(NSString *)event
           enterMethod:(NSString *)enterMethod
             extraInfo:(NSDictionary *)extraInfo
           isForceSend:(BOOL)isForceSend
{
    [self.repoTrack trackPostEvent:event enterMethod:enterMethod extraInfo:extraInfo isForceSend:isForceSend];
}

- (BOOL)isStory
{
    return self.repoContext.isIMRecord;
}

@end
