//
//  ACCMusicModelProtocolD.h
//  CameraClient
//
//  Created by yangying on 2021/6/17.
//

#ifndef ACCMusicModelProtocolD_h
#define ACCMusicModelProtocolD_h

#import <CreationKitArch/ACCMusicModelProtocol.h>

typedef NS_ENUM(NSInteger, ACCKaraokeLyricsType) {
    ACCKaraokeLyricsTypeLRC = 2,
    ACCKaraokeLyricsTypeKRC = 3
};

@protocol ACCMusicKaraokeAudioModelProtocol <NSObject>

#pragma mark - Server
/**
 * @note Value of properties in this section are derived from the network response.
 */

@property (nonatomic, assign) CGFloat volumeLoudness;
@property (nonatomic, assign) CGFloat volumePeak;
@property (nonatomic, assign) NSInteger playURLStart;
@property (nonatomic, strong) id<ACCURLModelProtocol> playURL;
@property (nonatomic, assign) NSInteger playURLDuration;

#pragma mark - Client
/**
 * @note Value of properties in this section are set by client.
 */

@property (nonatomic, copy) NSString *localPath;

@end

@protocol ACCMusicKaraokeTagModelProtocol <NSObject>

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *textColor;

@end

@protocol ACCMusicKaraokeModelProtocol <NSObject>

@property (nonatomic, strong) NSNumber *karaokeID;
@property (nonatomic, copy) NSString *karaokeIDStr;
@property (nonatomic, strong) NSNumber *musicID;
@property (nonatomic, copy) NSString *musicIDStr;
@property (nonatomic, strong) NSNumber *userCount;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, strong) id<ACCURLModelProtocol> coverHD;
@property (nonatomic, strong) id<ACCURLModelProtocol> coverLarge;
@property (nonatomic, strong) id<ACCURLModelProtocol> coverMedium;
@property (nonatomic, strong) id<ACCURLModelProtocol> coverThumb;
@property (nonatomic, strong) id<ACCMusicKaraokeAudioModelProtocol> originalSoundAudio;
@property (nonatomic, strong) id<ACCMusicKaraokeAudioModelProtocol> accompanimentAudio;

@property (nonatomic, assign) NSInteger duration; // music duration (ms)
@property (nonatomic, assign) ACCKaraokeLyricsType lyricsType;
@property (nonatomic, strong) id<ACCURLModelProtocol> lyricsURL;
@property (nonatomic, assign) NSInteger lyricsStart; // lyrics start time offset (ms)
@property (nonatomic, assign) BOOL showAuthor;
@property (nonatomic, copy) NSArray<id<ACCMusicKaraokeTagModelProtocol>> *tags;
@property (nonatomic, assign) BOOL isPGC;

@end

@protocol ACCMusicModelProtocolD <ACCMusicModelProtocol>

// karaoke
@property (nonatomic, strong) id<ACCMusicKaraokeModelProtocol> karaoke;
@property (nonatomic, assign, readonly) NSTimeInterval karaokeShootDuration;
@property (nonatomic, assign, readonly) NSTimeInterval karaokeAuditionDuration;

@end

#endif /* ACCMusicModelProtocolD_h */
