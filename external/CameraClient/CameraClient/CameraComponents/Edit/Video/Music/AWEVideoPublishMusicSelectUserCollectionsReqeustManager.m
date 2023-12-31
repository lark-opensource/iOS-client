//
//  AWEVideoPublishMusicSelectUserCollectionsReqeustManager.m
//  Pods
//
//  Created by resober on 2019/5/24.
//

#import "AWEVideoPublishMusicSelectUserCollectionsReqeustManager.h"

#import <CreativeKit/ACCServiceLocator.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CreationKitInfra/ACCLogHelper.h>

NSString *const kAWEVideoPublishMusicSelectUserCollectionsReqeustManagerCacheKey = @"kAWEVideoPublishMusicSelectUserCollectionsReqeustManagerCacheKey";

@interface AWEVideoPublishMusicSelectUserCollectionsReqeustManager ()
@property (nonatomic, assign) BOOL isProcessing;
@end

@implementation AWEVideoPublishMusicSelectUserCollectionsReqeustManager
- (instancetype)init {
    self = [super init];
    if (self) {
        [self resetRequestParams];
    }
    return self;
}

- (void)resetRequestParams {
    _curr = 0;
    _musicCntPerPage = 12;
    _hasMore = YES;
}

- (void)fetchCurrPageModelsWithCompletion:(AWEVideoPublishMusicSelectUserCollectionsReqeustManagerCompletion)completion {
    if (self.isProcessing) {
        return;
    }
    self.isProcessing = YES;
    __weak typeof(self) weakSelf = self;
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestCollectingMusicsWithCursor:@(_curr) count:@(_musicCntPerPage) completion:^(ACCMusicCollectListsResponseModel *model, NSError *error) {
        __strong typeof(weakSelf) strongSelf = self;
        BOOL success = error == nil;
        strongSelf.hasMore = model ? model.hasMore : YES;
        if (success) {
            strongSelf.curr = model.cursor.unsignedIntegerValue;
        }
        strongSelf.isProcessing = NO;
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, success, model);
        });
        if (error != nil) {
            AWELogToolError(AWELogToolTagMusic, @"%s %@", __PRETTY_FUNCTION__, error);
        }
    }];
}
@end
