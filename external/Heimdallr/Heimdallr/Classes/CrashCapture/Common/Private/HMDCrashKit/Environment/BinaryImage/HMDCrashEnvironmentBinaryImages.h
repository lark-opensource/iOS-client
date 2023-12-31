
/*! @header HMDCrashEnvironmentBinaryImages.h
 
    @abstract 1. 首先通过 @p HMDCrashEnvironmentBinaryImages_initWithDirectory 设置存储路径位置
              2. 然后调用 @p HMDCrashEnvironmentBinaryImages_save(xxx) 存储相应的 binary Image 信息
 
    @discussion 1. 很早之前我们是通过 @p _dyld_add_image_callback 函数回调，在异步线程进行存储信息
                2. 此函数有两个危害
                    [1] 很卡，存储信息基本高达 700+ 数据，容易卡住主线程，而且你记录文件 IO，没得办法只能异步子线程
                    [2] 等锁，这个函数和所有 @p _dyld_xxx 函数会共享相同的锁，导致部分启动崩溃无法记录 binary Image 信息
                       或者只要有呆瓜卡住持有这个锁不释放，这辈子都别想把 binary image 信息给存储下来
 
                3. 如何解决问题
                    [1] 我们分了三类存储 binaryImage 信息的位置
                        ( 1 ) @p image.main 存储从 @p _dyld_image_callback 获取的信息
                        ( 2 ) @p image.loadCommand 存储从 @p DATA_DIRTY.all_image_info 获取的信息
                        ( 3 ) @p image.realTime 存储在崩溃发生时，因为前两个笨比没记完，所以临时记录的数据
                    [2] 实现了无 dyld 锁结构的存储方式
                    [3] 废弃了没用的 @p write_image_on_crash 功能
 */

#ifndef HMDCrashEnvironmentBinaryImages_h
#define HMDCrashEnvironmentBinaryImages_h

#include "HMDMacro.h"

#pragma mark - Setup Interface (Objective-C)

#if __OBJC__

#import  <Foundation/Foundation.h>

/*!@function @p HMDCrashEnvironmentBinaryImages_initWithDirectory
   @discussion 初始化 binaryImage 存储路径，当前按照上层逻辑应该存储在 Active 文件夹
   @Note 非线程安全 */
HMD_EXTERN void HMDCrashEnvironmentBinaryImages_initWithDirectory(NSString * _Nonnull directory);

#endif  /* __OBJC__ */

#pragma mark - Save Interface (C)

/*!@function @p HMDCrashEnvironmentBinaryImages_save_async_blocked_mainFile
   @discussion 存储 Binary Image 主文件，会 @b 异步 到非当前线程存储，该次调用存在被其他线程 @b 阻塞 的可能
   @note 该函数调用需要保证在调用 @p initWithDirectory 函数之后，线程安全 */
HMD_EXTERN void HMDCrashEnvironmentBinaryImages_save_async_blocked_mainFile(void);

/*!@function @p HMDCrashEnvironmentBinaryImages_is_mainFile_mostly_finished
   @abstract 是否 @p mainFile 主 Binary Image 文件大部分都记录完成咯，是用来给崩溃捕获的时刻测试
             如果大部分都存储完了，那就皆大欢喜；如果没有那就得做些别的事情咯
 */
HMD_EXTERN bool HMDCrashEnvironmentBinaryImages_is_mainFile_mostly_finished(void);

/*!@function @p HMDCrashEnvironmentBinaryImages_save_async_nonBlocked_loadCommandFile
   @discussion 存储 Load Command 附文件，会 @b 异步 到非当前线程存储，该次调用 @b 不会被阻塞
   @note 该函数调用需要保证在调用 @p initWithDirectory 函数之后，线程安全 */
HMD_EXTERN void HMDCrashEnvironmentBinaryImages_save_async_nonBlocked_loadCommandFile(void);

/*!@function @p HMDCrashEnvironmentBinaryImages_prepare_for_realTimeFile
   @discussion 准备存储 realTimeFile 及时文件的必要前置条件，其实就是准备好 FD 等准备写入
   @note 该函数调用需要保证在调用 @p initWithDirectory 函数之后，线程安全 */
HMD_EXTERN void HMDCrashEnvironmentBinaryImages_prepare_for_realTimeFile(void);

/*!@function @p HMDCrashEnvironmentBinaryImages_save_sync_nonBlocked_realTimeFile
   @discussion 存储 realTimeFile 及时文件，会 @b 同步 到当前线程存储，该次调用 @b 不会被阻塞
   @note 主要是怕崩溃发生的时刻，上面两个瓜皮文件还没有记录完整，我能怎么办，只能搞这个咯
   @note 该函数调用需要保证在调用 @p initWithDirectory 和 @p prepare_for_realTimeFile 函数之后，线程安全 */
HMD_EXTERN void HMDCrashEnvironmentBinaryImages_save_sync_nonBlocked_realTimeFile(void);

#pragma mark - Load Interface (Objective-C)

#if !SIMPLIFYEXTENSION

#if __OBJC__

#import "HMDCrashBinaryImage.h"

@interface HMDImageOpaqueLoader : NSObject

/*!@property envAbnormal
   @abstract 标记是否找到过疑似越狱镜像
 */
@property(nonatomic, readonly) BOOL envAbnormal;

@property(nonatomic, readonly) NSUInteger currentlyImageCount;

@property(nonatomic, readonly, nullable) NSArray<HMDCrashBinaryImage *> *currentlyUsedImages;

- (instancetype _Nullable)init NS_UNAVAILABLE;

- (instancetype _Nullable)initWithDirectory:(NSString * _Nonnull)directory NS_DESIGNATED_INITIALIZER;

- (HMDCrashBinaryImage * _Nullable)imageForAddress:(uintptr_t)address;

@end

#endif  /* __OBJC__ */

#endif /* !SIMPLIFYEXTENSION */

#endif /* HMDCrashEnvironmentBinaryImages_h */
