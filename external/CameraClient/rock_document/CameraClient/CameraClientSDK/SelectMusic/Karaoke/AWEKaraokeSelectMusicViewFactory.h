//
//  AWEKaraokeSelectMusicViewFactory.h
//  AWEStudioService-Pods-Aweme
//
//  Created by bytedance on 2021/8/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicKaraokeTagModelProtocol;

@interface AWEKaraokeSelectMusicViewFactory : NSObject

+ (instancetype)sharedInstance;
+ (void)destroySharedInstance;

- (nullable UIImage *)tagFromModel:(id<ACCMusicKaraokeTagModelProtocol>)tagModel;

@end

NS_ASSUME_NONNULL_END
