//
//  ACCCommerceMusicServiceProtocol.h
//  AWEStudio-Pods-Aweme
//
//  Created by Zhihao Zhang on 2021/2/7.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

// TODO: 先沉下去，后续改掉，不要和商业化音乐产生关系
@protocol ACCCommerceMusicServiceProtocol <NSObject>

- (UIView *)loadMusicListAdView:(NSString *)musicID categoryName:(NSString *)name;
- (NSArray *)connectMusicsOfCMCChallenge:(id)challengeModel;

@end

FOUNDATION_STATIC_INLINE id<ACCCommerceMusicServiceProtocol> ACCCommerceMusicService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCCommerceMusicServiceProtocol)];
}

NS_ASSUME_NONNULL_END
