//
//  ACCRepoCanvasBusinessModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/6.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoCanvasBusinessModel : NSObject <NSCopying, ACCRepositoryContextProtocol>

@property (nonatomic, strong) id<ACCMusicModelProtocol> rePostMusicModel;
@property (nonatomic, copy) NSString *musicID;
// no need to save draft
@property (nonatomic, assign) NSInteger socialType;

@end

@interface AWEVideoPublishViewModel (RepoCanvasBusiness)
 
@property (nonatomic, strong, readonly) ACCRepoCanvasBusinessModel *repoCanvasBusiness;
 
@end

NS_ASSUME_NONNULL_END
