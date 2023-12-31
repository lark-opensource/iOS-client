//
//  ACCVideoMusicProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/6.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCMusicCollectListsResponseModel;

typedef void (^ACCVideoMusicModelFetchURLCompletion)(NSURL *localURL, NSError *error);
typedef void (^ACCVideoMusicAndLyricModelFetchURLCompletion)(NSURL *localMusicURL, NSURL *localLyricURL, NSError *error);
typedef void (^ACCMusicDataBlock)(id<ACCMusicModelProtocol> model, NSError *error);
typedef void (^ACCPhotoMovieMusicListResponseBlock)(NSArray<id<ACCMusicModelProtocol>> *musicList);
typedef void (^ACCMusicCollectListsResponseBlock)(ACCMusicCollectListsResponseModel *model, NSError *error);
typedef void (^ACCMusicCollectResponseBlock)(BOOL success, NSString *_Nullable message, NSError *_Nullable error);

@protocol ACCVideoMusicProtocol <NSObject>

- (BOOL)downloadedMusic:(id<ACCMusicModelProtocol>)music;

- (NSURL *)localURLForMusic:(id<ACCMusicModelProtocol>)music;

- (NSURL *)localLyricURLForMusic:(id<ACCMusicModelProtocol>)music;

- (void)fetchLocalURLForMusic:(id<ACCMusicModelProtocol>)music
                 withProgress:(void (^ _Nullable)(float progress))progressHandler
                   completion:(ACCVideoMusicModelFetchURLCompletion _Nullable)completion;

- (void)fetchLocalURLForMusic:(id<ACCMusicModelProtocol>)music
                     lyricURL:(NSString * _Nullable)lyricURL
                   extraTrack:(NSDictionary * _Nullable)extraTrackDic
                 withProgress:(void (^ _Nullable)(float progress))progressHandler
                   completion:(ACCVideoMusicAndLyricModelFetchURLCompletion _Nullable)completion;

- (void)fetchLocalURLForMusic:(id<ACCMusicModelProtocol>)music
                     lyricURL:(NSString * _Nullable)lyricURL
                 withProgress:(void (^ _Nullable)(float progress))progressHandler
                   completion:(ACCVideoMusicAndLyricModelFetchURLCompletion _Nullable)completion;

- (void)requestMusicItemWithID:(NSString *)itemID
                    completion:(nullable ACCMusicDataBlock)block;

- (void)requestMusicItemWithID:(NSString *)itemID
              additionalParams:(NSDictionary *)params
                    completion:(nullable ACCMusicDataBlock)block;

- (void)refreshMusicItem:(id<ACCMusicModelProtocol>)model completion:(dispatch_block_t)block;

- (void)requestCollectingMusicWithID:(NSString *)itemID
                             collect:(BOOL)collect
                          completion:(ACCMusicCollectResponseBlock)block;

- (void)requestCollectingMusicsWithCursor:(NSNumber *)cursor
                                    count:(nullable NSNumber *)count
                               completion:(nullable ACCMusicCollectListsResponseBlock)block;

@end

FOUNDATION_STATIC_INLINE id<ACCVideoMusicProtocol> ACCVideoMusic() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCVideoMusicProtocol)];
}

@protocol ACCMusicCollectMessage <NSObject>
- (void)didToggleMusicCollectStateWithMusicId:(NSString *)musicId collect:(BOOL)collect sender:(id)sender;
@end

NS_ASSUME_NONNULL_END
