//
//  AWERepoDraftModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/20.
//

#import <CreationKitArch/ACCRepoDraftModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCRepoDraftSavePolicy) {
    ACCRepoDraftSavePolicyDefault,
    ACCRepoDraftSavePolicyForbiddenBackup,
    ACCRepoDraftSavePolicyForbiddenAll
};

@interface AWERepoDraftModel : ACCRepoDraftModel <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@property (nonatomic, strong) id<ACCDraftModelProtocol, ACCPublishRepository> originalDraft;

@property (nonatomic,   copy) NSString *userID;
@property (nonatomic, strong) NSDate *saveDate;
@property (nonatomic, assign) BOOL isReceived;

/// 管理员录屏发布成功生成的草稿id 上传音轨接口需带上
@property (nonatomic, strong) NSNumber *adminDraftId;

@property (nonatomic, assign) ACCRepoDraftSavePolicy draftSavePolicy;

@property (nonatomic, assign) NSInteger postPageFrequency; //不跨机迁移

// return nil if not from draft, return draft save time if from draft
- (nullable NSString *)tagForDraftFromBackEdit;

@end

@interface AWEVideoPublishViewModel (AWERepoDraft)
 
@property (nonatomic, strong, readonly) AWERepoDraftModel *repoDraft;
 
@end
 

NS_ASSUME_NONNULL_END
