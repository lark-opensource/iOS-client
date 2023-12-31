//
//  AWERepoFlowerTrackModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by qy on 2021/11/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface AWERepoFlowerTrackModel : NSObject<ACCRepositoryContextProtocol, ACCRepositoryTrackContextProtocol>

@property (nonatomic,   copy) NSString *_Nullable lastFlowerPropChooseMethod;
@property (nonatomic,   copy) NSString *_Nullable schemaEnterMethod;

@property (nonatomic, assign) BOOL fromFlowerCamera;
@property (nonatomic, assign) BOOL isFromShootProp;
@property (nonatomic, assign) BOOL isInRecognition;

- (BOOL)shouldAddFlowerShootParams:(NSDictionary *)infos;
- (NSDictionary *_Nullable)flowerEventShootExtra;
- (NSString *_Nullable)lastChooseMethod;
- (NSString *_Nullable)flowerTabName;

@end

@interface AWEVideoPublishViewModel (RepoFlowerTrack)

@property (nonatomic, strong, readonly, nullable) AWERepoFlowerTrackModel *repoFlowerTrack;

@end
