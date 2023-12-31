//
//  ACCRepoCanvasModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/6.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <TTVideoEditor/IESMMCanvasSource.h>
#import <TTVideoEditor/IESMMCanvasConfig.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCCanvasContentType) {
    ACCCanvasContentTypePhoto = 0,
    ACCCanvasContentTypeVideo = 1,
};

@interface ACCRepoCanvasModel : NSObject <NSCopying, ACCRepositoryContextProtocol>

/* input params no need for draft migration Begin */
@property (nonatomic, assign) ACCCanvasContentType canvasContentType;

@property (nonatomic, strong) NSNumber *minimumScale;
@property (nonatomic, strong) NSNumber *maximumScale;

// no need to save draft Begin
@property (nonatomic, strong) IESMMCanvasConfig *config;
@property (nonatomic, strong) IESMMCanvasSource *source;

@property (nonatomic, assign) CGFloat videoDuration; // default is 10

@property (nonatomic, strong) NSURL *videoURL;
// no need to save draft End
/* input params no need for draft migration End */

@property (nonatomic, strong) NSNumber *groupId; //sticker group id

@end

@interface AWEVideoPublishViewModel (RepoCanvas)
 
@property (nonatomic, strong, readonly) ACCRepoCanvasModel *repoCanvas;
 
@end

NS_ASSUME_NONNULL_END
