//
//  AWEStudioSearchServiceProtocol.h
//  AWEStudio-Pods-Aweme-AWEStudio
//
//  Created by Chen Long on 2020/11/17.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

// TODO: @zzh 逻辑有点怪，先沉下去，后续去掉
@protocol ACCSearchServiceProtocol <NSObject>

- (void)searchHybridAudioPause;

@end

FOUNDATION_STATIC_INLINE id<ACCSearchServiceProtocol> ACCSearchService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCSearchServiceProtocol)];
}

NS_ASSUME_NONNULL_END
