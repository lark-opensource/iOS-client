//
//  ACCRepoDuetModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/23.
//

#import "ACCRepoDuetModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>

//const int kAWEModernVideoEditDuetEnlargeMetric = 10;

@interface AWEVideoPublishViewModel (RepoDuet) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoDuet)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoDuetModel.class];
}

- (ACCRepoDuetModel *)repoDuet
{
    ACCRepoDuetModel *duetModel = [self extensionModelOfClass:ACCRepoDuetModel.class];
    NSAssert(duetModel, @"extension model should not be nil");
    return duetModel;
}

@end

@implementation ACCRepoDuetModel

#pragma mark - public

- (NSArray *)challengeNames {
    NSMutableArray *challenges = @[].mutableCopy;
    if (self.isDuet) {
        for (id<ACCChallengeModelProtocol> challenge in self.duetSource.challengeList) {
            if (challenge.isCommerce) {
                if (challenge.challengeName.length != 0 && ![challenges containsObject:challenge.challengeName]) {
                    [challenges addObject:challenge.challengeName];
                }
            }
        }
    }
    return challenges.copy;
}

- (NSArray *)challengeIDs {
    NSMutableArray *challenges = @[].mutableCopy;
    if (self.isDuet) {
        for (id<ACCChallengeModelProtocol> challenge in self.duetSource.challengeList) {
            if (challenge.isCommerce) {
                if (challenge.itemID.length != 0 && ![challenges containsObject:challenge.itemID]) {
                    [challenges addObject:challenge.itemID];
                }
            }
        }
    }
    return challenges.copy;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    ACCRepoDuetModel *model = [[[self class] alloc] init];
    model.isDuet = self.isDuet;

    model.duetSource = self.duetSource;
    model.duetLocalSourceURL = self.duetLocalSourceURL.copy;
    model.furthestStep = self.furthestStep;
    // Cut same
    model.duetLayout = self.duetLayout;
    model.duetOrCommentChainlength = self.duetOrCommentChainlength;
    return model;
}


#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_errorLogParams
{
    return @{
        @"is_duet":@(self.isDuet),
        @"duet_source":self.duetSource.itemID?:@"",
        @"duet_last_furthest_step":@(self.furthestStep),
        @"duet_layout":self.duetLayout?:@"",
    };
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol - Optional

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *param = @{}.mutableCopy;
    param[@"duet_layout"] = self.duetLayout;
    return param.copy;
}

@end
