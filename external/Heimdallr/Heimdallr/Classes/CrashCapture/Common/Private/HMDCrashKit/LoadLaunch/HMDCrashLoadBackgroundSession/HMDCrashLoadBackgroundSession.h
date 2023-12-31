
/*!@header HMDCrashLoadBackgroundSession.h
   @author somebody
   @abstract crash load launch background session
 */

#import <Foundation/Foundation.h>
#import "HMDCLoadContext.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDCLoadContext;

@interface HMDCrashLoadBackgroundSession : NSObject

+ (instancetype _Nullable)sessionWithContext:(HMDCLoadContext *)context;

#pragma mark - Access only in main thread

// 上次启动上报的内容 (如果是 null 就意味着没有
@property(direct, nonatomic, nullable, readonly) NSArray<NSString *> *previousUploading;

- (void)uploadPath:(NSString *)path name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
