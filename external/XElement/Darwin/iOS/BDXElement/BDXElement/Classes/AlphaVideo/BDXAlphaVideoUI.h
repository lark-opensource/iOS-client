//
//  BDXAlphaVideoUI.h
//  BDXElement
//
//  Created by li keliang on 2020/11/23.
//

#import "BDXHybridUI.h"

@protocol BDXAlphaVideoUIDelegate <NSObject>

- (BOOL)loadZipFromResourceFetcher:(NSURL *)URL
                        completion:(void (^)(NSURL *URL, NSURL *unzipURL, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, BDXAlphaVideoErrorCode) {
    BDXAlphaVideoErrorCodeResourcesNotFound = -1,
    BDXAlphaVideoErrorCodeUnzipFail = -2,
    BDXAlphaVideoErrorCodeConfigJsonParserFail = -3,
    BDXAlphaVideoErrorCodeVideoPosterSetFail = -4,
    BDXAlphaVideoErrorCodeVideoLastframeSetFail = -5,
    BDXAlphaVideoErrorCodeVideoUnknownException = -6,
    BDXAlphaVideoErrorCodeAbnormalPlayEnd = -9,
    BDXAlphaVideoErrorCodeResourceTypeNotSupported = -13,
};
@interface BDXAlphaVideoUI : BDXHybridUI<UIView *>

@property (nonatomic) BOOL isVideoPlaying;
@property (nonatomic, weak) id<BDXAlphaVideoUIDelegate> uiDelegate;
@property (nonatomic) NSNumber *videoDuration;
- (BOOL)isVideoPlaying;
- (NSNumber*) getVideoDuration;
- (void)updateFrameSize;
- (NSUInteger)getState;
- (BOOL)isPrepared;
@end

NS_ASSUME_NONNULL_END
