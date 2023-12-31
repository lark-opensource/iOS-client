//
//  UITrackerManager.h
//  Heimdallr
//
//  Created by joy on 2018/4/25.
//

#import <Foundation/Foundation.h>
#import "HeimdallrModule.h"
#import "HMDUITrackerManagerSceneProtocol.h"

@class HMDUITrackRecord;



extern NSString * _Nonnull const kHMDUITrackerSceneDidChangeNotification;

@interface HMDUITrackerManager : HeimdallrModule <HMDUITrackerManagerSceneProtocol>

+ (nonnull instancetype)sharedManager;

@property (nonatomic, strong, nullable) NSMutableArray<HMDUITrackRecord*>* events;

@property (nonatomic, assign) NSUInteger flushCount;
@property (nonatomic, assign) double flushInterval;
@property (nonatomic, assign) NSUInteger uploadCount;
@property (nonatomic, assign) double uploadInterval;
@property (atomic, copy, readonly, nullable) NSString *scene;//当前场景，取当前正在显示的vc的类名
@property (atomic, copy, readonly, nullable) NSString *lastScene;//正在退出的场景，取当前正在退出的vc的类名
@property (atomic, strong, readonly, nullable) NSNumber *sceneInPushing; // 场景正在切换 number.boolValue

- (nullable NSArray<HMDUITrackRecord*>*)ui_actionRecordsInAppTimeFrom:(CFTimeInterval)fromTime
                                                          to:(CFTimeInterval)toTime
                                                            sessionID:(NSString * _Nullable)sessionID
                                                          recordClass:(Class _Nullable )recordClass;

//返回当前用户操作轨迹相关的所有信息
- (nullable NSDictionary *)sharedOperationTrace;
- (nullable NSArray *)getUITrackerDataWithRecords:(NSArray<HMDUITrackRecord *> * _Nullable)records;
// 获取records
- (nullable NSArray *)fetchUploadRecords;

- (nullable UIWindow *)getKeyWindow;

/**
 * 获取并记录keyWindow的视图栈
 * @param need 是否获取view的description，开启肯能会影响耗时及报文大小
 */
- (void)recordViewHierarchyForKeyWindowWithDetail:(BOOL)need;

/**
 * 获取并记录指定UIWindow的视图栈
 * @param window 指定UIWindow
 * @param need 是否获取view的description，开启肯能会影响耗时及报文大小
 */
- (void)recordViewHierarchyForWindow:(nonnull UIWindow *)window WithDetail:(BOOL)need;

/**
 * 通过自定义异常上传存储的视图栈
 * @param title 异常标题（用于聚合）
 * @param subTitle 子标题（用于聚合）
 */
- (void)uploadViewHierarchyWithTitle:(nonnull NSString *)title subTitle:(nonnull NSString *)subTitle;
@end


