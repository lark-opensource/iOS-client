//
//  ACCRepoPropModel.m
//  CameraClient
//
//  Created by haoyipeng on 2020/10/25.
//

#import "ACCRepoPropModel.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCRepoVideoInfoModel.h"

@interface AWEVideoPublishViewModel (RepoProp) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoProp)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoPropModel.class];
    return info;
}

- (ACCRepoPropModel *)repoProp
{
    ACCRepoPropModel *propModel = [self extensionModelOfClass:ACCRepoPropModel.class];
    NSAssert(propModel, @"extension model should not be nil");
    return propModel;
}

@end

@implementation ACCRepoPropModel
@synthesize repository;
@synthesize propSelectedFrom = _propSelectedFrom;

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    ACCRepoPropModel *copy = [[[self class] alloc] init];
    copy.totalStickerSavePhotos = self.totalStickerSavePhotos;
    return copy;
}

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    return result;
}

#pragma mark - Public

- (NSArray <NSString *>*)stickerBindedChallengeArray
{
    ASSERT_IN_SUB_CLASS
    return @[];
}

#pragma mark - Getter
- (NSString *)propSelectedFrom
{
    NSMutableArray *array = [NSMutableArray array];
    
    ACCRepoVideoInfoModel *repoVideoInfo = [self.repository extensionModelOfClass:[ACCRepoVideoInfoModel class]];
    [repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(id<ACCVideoFragmentInfoProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!ACC_isEmptyString(obj.propSelectedFrom)) {
            [array addObject:obj.propSelectedFrom];
        }
    }];
    
    if (array.count > 0) {
        return [array componentsJoinedByString:@","];
    }

    return nil;
}

- (NSMutableDictionary<NSString *,NSString *> *)cacheStickerChallengeNameDict
{
    if (!_cacheStickerChallengeNameDict) {
        _cacheStickerChallengeNameDict = [NSMutableDictionary dictionary];
    }
    return _cacheStickerChallengeNameDict;
}

@end
