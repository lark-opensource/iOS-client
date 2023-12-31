//
//  ACCRepoDraftModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/20.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@class AWEVideoPublishDraftTempProductModel;
@protocol ACCDraftModelProtocol;

@interface ACCRepoDraftModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *originalModel;

@property (nonatomic,   copy) NSString *taskID;
@property (nonatomic, strong) NSString *draftPath;
@property (nonatomic, assign) BOOL isBackUp;
@property (nonatomic, assign, readonly) BOOL isDraft;
@property (nonatomic, strong) AWEVideoPublishDraftTempProductModel *draftTempProduct;
@property (nonatomic, assign) NSInteger editFrequency;

- (NSString *)draftFolder;

@end

@interface AWEVideoPublishViewModel (RepoDraft)
 
@property (nonatomic, strong, readonly) ACCRepoDraftModel *repoDraft;
 
@end
 

NS_ASSUME_NONNULL_END
