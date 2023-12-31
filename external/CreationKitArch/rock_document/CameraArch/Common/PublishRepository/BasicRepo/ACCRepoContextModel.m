//
//  ACCRepoContextModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/20.
//

#import "ACCRepoContextModel.h"

@interface ACCRepoContextModel ()

@end

@interface AWEVideoPublishViewModel (RepoContext) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoContext)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoContextModel.class];
}

- (ACCRepoContextModel *)repoContext
{
    ACCRepoContextModel *contextModel = [self extensionModelOfClass:ACCRepoContextModel.class];
    NSAssert(contextModel, @"extension model should not be nil");
    return contextModel;
}

@end


@interface ACCRepoContextModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@end

@implementation ACCRepoContextModel

- (instancetype)init
{
    if (self = [super init]) {
        _videoType = AWEVideoTypeNormal;
        _createVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoContextModel *model = [[[self class] alloc] init];
    model.createVersion = self.createVersion;
    model.uuid = self.uuid;
    model.maxDuration = self.maxDuration;
    model.videoSource = self.videoSource;
    model.videoType = self.videoType;
    model.feedType = self.feedType;
    model.videoLenthMode = self.videoLenthMode;
    model.photoToVideoPhotoCountType = self.photoToVideoPhotoCountType;
    model.videoRecordType = self.videoRecordType;

    //IM
    model.recordSourceFrom = self.recordSourceFrom;
    
    return model;
}

#pragma mark - getter

- (NSString *)createId
{
    if (!_createId) {
        _createId = [[NSUUID UUID] UUIDString];
    }
    return _createId;
}

- (NSString *)uuid
{
    if (!_uuid) {
        _uuid = [[NSUUID UUID] UUIDString];
    }
    return _uuid;
}

- (BOOL)isMVVideo
{
    return AWEVideoTypeMV == self.videoType;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;


#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_errorLogParams
{
    return @{
        @"uuid":self.uuid?:@"",
        @"create_version":self.createVersion?:@"",
        @"maxDuration":@(self.maxDuration),
        @"video_source":@(self.videoSource),
        @"video_type":@(self.videoType),
    };
}

@end
