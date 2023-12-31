//
//  ACCHeimdallrProtocol.h
//  AWEStudio-Pods-Aweme
//
//  Created by liujinze on 2020/9/8.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCHeimdallrProtocol <NSObject>

- (unsigned long long)folderSizeAtPath:(NSString *)folderPath;
- (BOOL)isMemoryUseExceeded;

@end

FOUNDATION_STATIC_INLINE id<ACCHeimdallrProtocol> ACCHeimdallrService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCHeimdallrProtocol)];
}

NS_ASSUME_NONNULL_END
