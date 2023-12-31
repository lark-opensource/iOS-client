
/*!@header HMDWPDynamicSafeData
   @abstract 异步安全的数据返回方案
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDWPDynamicSafeData : NSObject

#pragma mark - 异步数据传递流程

#pragma mark 首先[主要线程]创建时根据需要同步数据类型不同进行初始化(选择其中1个) 然后创建异步线程执行工作

//返回类型是 数据类型 (非 OC object)
+ (instancetype)safeDataWithSize:(NSUInteger)size;

// 返回类型是 OC Object
+ (instancetype)safeDataStoreObject;

#pragma mark [异步线程]存放数据使用以下方法 (无论是OC还是DataBlob)

/*!@method storeData:
   @discussion 异步线程安全存储返回给主线程的方法
   @code
    id object;  // If sharedData type is OC object
    [safeData storeData:&object];
 
    int value;  // If sharedData type is integer
    [safeData storeData:&value];
   @endcode
 */
- (void)storeData:(void *)data;

#pragma mark (主要线程)在任意时刻读取数据方法 (和创建时使用的方法匹配)

// 创建时使用的是 safeDataWithSize: 那么用此方法获取数据
- (BOOL)getDataIfPossible:(void *)data;

// 创建时使用的是 safeDataStoreObject 那么用此方法获取数据
- (id _Nullable)getObject;

#pragma mark - 安全的原子数据同步

/*!@property atomicInfo
   @discussion 初始化为 0 ( 对应 HMDWPCallerStatusWaiting 值 ) 这个很关键
 */
@property(atomic) uint64_t atomicInfo;

@end

NS_ASSUME_NONNULL_END
