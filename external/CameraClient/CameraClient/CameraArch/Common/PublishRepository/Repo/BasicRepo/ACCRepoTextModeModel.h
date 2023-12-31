//
//  ACCRepoTextModeModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/26.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEStoryTextImageModel;

@interface ACCRepoTextModeModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

#pragma mark - 文字模式
@property (nonatomic, assign) BOOL isTextMode; // 文字模式

@property (nonatomic, strong, nullable) AWEStoryTextImageModel *textModel; // text model from text mode in recorder page; should save in draft, clear when text save into player

@end

@interface AWEVideoPublishViewModel (RepoTextMode)
 
@property (nonatomic, strong, readonly) ACCRepoTextModeModel *repoTextMode;
 
@end

NS_ASSUME_NONNULL_END
