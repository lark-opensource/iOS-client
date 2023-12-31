//
//  BDXVideoViewController.h
//  BDXElement
//
//  Created by bill on 2020/3/25.
//

#import <UIKit/UIKit.h>
#import "BDXVideoPlayerVideoModel.h"
#import "BDXVideoPlayerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXVideoViewController : UIViewController<BDXVideoFullScreenPlayer>

@property (nonatomic, assign) BOOL autoLifecycle;
/// 重复播放，默认 NO
@property (nonatomic, assign) BOOL repeated;
/// 设置要播放的视频，覆盖 playURL, coverURL
@property (nonatomic, strong, nullable) BDXVideoPlayerVideoModel *video;
/// 埋点参数
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *eventParams;

@property (nonatomic, assign) NSTimeInterval initPlayTime;

@property (nonatomic, weak) id <BDXVideoPlayProgressDelegate> playerDelegate;

- (BOOL)play;

- (BOOL)pause;

- (void)dismiss;

- (instancetype)initWithCoverImageURL:(NSString *)url;
- (instancetype)initWithCoverImage:(UIImage *)image;

- (void)show:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
