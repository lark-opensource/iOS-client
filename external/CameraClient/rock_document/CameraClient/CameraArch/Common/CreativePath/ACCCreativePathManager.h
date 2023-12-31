//
//  ACCCreativePathManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCCreativePathManagable.h>
#import "ACCCreativePage.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const kACCCreativePathEnterNotification;
FOUNDATION_EXPORT NSString * const kACCCreativePathExitNotification;

@interface ACCCreativePathManager : NSObject <ACCCreativePathManagable>

+ (instancetype)manager;

@property (nonatomic, assign, readonly) BOOL onPath;
@property (nonatomic, assign, readonly) ACCCreativePage currentPage;

- (void)checkWindow;
- (void)setupObserve:(UIViewController *)viewController;
- (void)setupObserve:(UIViewController *)viewController page:(ACCCreativePage)page;

@end

NS_ASSUME_NONNULL_END
