//
//  ACCMusicModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/1/12.
//

#ifndef ACCMusicModelProtocol_h
#define ACCMusicModelProtocol_h

#import "ACCURLModelProtocol.h"
#import "ACCChallengeModelProtocol.h"

#import <Mantle/Mantle.h>

@protocol ACCChallengeModelProtocol;

typedef NS_ENUM(NSUInteger, ACCMusicLyricType) {
    ACCMusicLyricTypeJSON = 10, // JSON list, KuWo lyrics, from Preview_ start_ Time to start playing
    ACCMusicLyricTypeTXT  = 11, // TXT text, clip lyrics, play directly from the beginning
};

@protocol ACCMusicClimaxModelProtocol <NSObject>
@property (nonatomic, strong) NSNumber *startPoint;
@end

@protocol ACCExternalMusicModelProtocol <NSObject>
@property (nonatomic, copy) NSString *thirdPlatformName;
@property (nonatomic, copy) NSString *universalLink;
@end

@protocol ACCMusicMatchedSongModelProtocol <NSObject>
@property (nonatomic, copy) NSString *h5URL;
@end

@protocol ACCMusicTagModelProtocol <NSObject>
@property (nonatomic, copy) NSString *tagTitle;
@property (nonatomic, copy) NSString *tagTitleColor;
@property (nonatomic, copy) NSString *tagColor;
@property (nonatomic, copy) NSString *tagBorderColor;
@property (nonatomic, copy) NSString *tagTitleLightColor;
@property (nonatomic, copy) NSString *tagLightColor;
@property (nonatomic, copy) NSString *tagBorderLightColor;
@property (nonatomic, copy) NSString *tagType;
@end

@protocol ACCPositonProtocol <NSObject>
@property (nonatomic,assign) NSInteger begin;
@property (nonatomic,assign) NSInteger end;
@end

@protocol ACCMusicModelProtocol <NSCoding, MTLJSONSerializing>
@property (nonatomic, copy, nullable) NSString *musicID;
@property (nonatomic, strong) NSURL *localURL;
@property (nonatomic, strong) NSURL *loaclAssetUrl;
@property (nonatomic, strong) NSURL *originLocalAssetUrl; // local asset url before copy to draft
@property (nonatomic, strong) NSURL *localStrongBeatURL;

@property (nonatomic, assign) CGFloat previewStartTime;// Clip start time

@property (nonatomic,   copy) NSString *lyricUrl;// The URL of the whole song lyrics
@property (nonatomic,   copy) NSString *shortLyric;
@property (nonatomic, assign) ACCMusicLyricType lyricType;// Types of lyrics

@property (nonatomic,   copy) NSString *musicSelectedFrom;
@property (nonatomic,   copy) NSString *awe_selectPageName;// edit_page,shoot_page

@property (nonatomic, assign) BOOL isPGC; // judge music is PGC or UGC
@property (nonatomic, assign) BOOL isFavorite; // is added to user's favorites
@property (nonatomic, assign) BOOL preventDownload;// Can I save a video shot with this music to an album
@property (nonatomic, assign) BOOL isOriginal; // Is it an original musician
@property (nonatomic, assign) BOOL isCommerceMusic;
@property (nonatomic, assign) BOOL isOriginalSound; // Is it the user's original voice
@property (nonatomic, assign) BOOL isFromImportVideo;
@property (nonatomic, assign) BOOL isDownloading;// Are you downloading
@property (nonatomic, assign) BOOL showRecommendLabel;
@property (nonatomic, assign) BOOL canBackgroundPlay; // Awestudio is in use. How to remove it

// The following is the "original musician (Spotlight musician certification)" information that created this music
@property (nonatomic, copy) NSString *ownerNickname;
@property (nonatomic, assign) BOOL dmvAutoShow; ///< add lyrics sticker by default
@property (nonatomic, copy, nullable) NSString *categoryId;

@property (nonatomic, strong) id<ACCMusicClimaxModelProtocol> climax;
@property (nonatomic, strong) id<ACCMusicMatchedSongModelProtocol> matchedSong;
@property (nonatomic, strong, nullable) id<ACCChallengeModelProtocol> challenge;

@property (nonatomic, copy) NSArray<id<ACCExternalMusicModelProtocol>> *externalMusicModelArray;
@property (nonatomic, copy) NSArray<id<ACCMusicTagModelProtocol>> *musicTags;
@property (nonatomic, copy) NSArray<id<ACCPositonProtocol>> *shortLyricHighlights;

@property (nonatomic, strong) NSNumber *collectStat;
@property (nonatomic, strong) NSNumber *userCount;

@property (nonatomic, copy) NSString *matchedPGCMixedAuthor;


@property (nonatomic, strong) NSNumber *videoDuration;

- (BOOL)isOffLine;

// readonly property need to be trans to getter, or the mantle will crash due to readonly defined in protocol not have a ivar
- (id<ACCURLModelProtocol>)playURL;
- (id<ACCURLModelProtocol>)thumbURL;
- (id<ACCURLModelProtocol>)strongBeatURL;
- (id<ACCURLModelProtocol>)mediumURL;

- (NSString *)musicName;
- (NSString *)authorName;
- (NSString *)offlineDesc;
- (NSNumber *)duration;
- (NSNumber *)shootDuration; // Shooting duration
- (NSNumber *)auditionDuration; // Duration of audition

/**
 *@brief return  'Contains music from: {PGC sound name} - {PGC artist name}'
 *       or nil if invalid
 */
- (NSString *)awe_matchedPGCMusicInfoStringWithPrefix;

- (id)copy;

@optional

// export local audio music
@property (nonatomic, assign) BOOL isFromiTunes;
@property (nonatomic, assign) BOOL isLocalScannedMedia;

@end

@protocol ACCMusicModelProtocol;
@protocol ACCVideoMusicListModelProtocol <NSObject>

@property (nonatomic, strong) NSString *requestID;

@property (nonatomic,   copy, readonly) NSArray<id<ACCMusicModelProtocol>> *musicList;
@property (nonatomic, strong) NSNumber *cursor;
@property (nonatomic, strong) NSNumber *musicType;
@property (nonatomic, assign) BOOL hasMore;

@end

@protocol ACCMusicCollectListModelProtocol <NSObject>

@property (nonatomic,   copy) NSArray<id<ACCMusicModelProtocol>> *mcList;
@property (nonatomic, strong) NSNumber *cursor;
@property (nonatomic, assign) BOOL hasMore;

@end


#endif /* ACCMusicModelProtocol */
