//
//  IESGurdUpdateStatisticModel.h
//  IESGeckoKit
//
//  Created by xinwen tan on 2021/10/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdUpdateStageModel : NSObject

@property (nonatomic, copy) NSString *prefix;      // 属性转成json字符串时的字段前缀
@property (nonatomic, copy) NSString *errMsg;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) BOOL result;
@property (nonatomic, assign) int errCode;
@property (nonatomic, assign) int downloadErrCode;
@property (nonatomic, assign) int failedTimes;
@property (nonatomic, strong) NSDate *startTime;

@end

@interface IESGurdUpdateStatisticModel : NSObject

@property (nonatomic, assign) BOOL updateResult;
@property (nonatomic, assign) BOOL createByReboot;       // 当激活未成功，下次重启直接使用cache激活时，这个值为1

@property (nonatomic, assign) int downloadType;
@property (nonatomic, assign) uint64_t patchID;

@property (nonatomic, assign) NSInteger durationTotal;      // 整个更新的时间
@property (nonatomic, assign) NSInteger durationLastStage;  // 最后一个阶段的时间
// 以下时间都只考虑最后一个阶段，因为之前的阶段都是失败的，没有统计意义
@property (nonatomic, assign) NSInteger durationDownload;          // 包含重试的下载时间
@property (nonatomic, assign) NSInteger durationDownloadLastTime;  // 不包含重试，最后一次下载时间
@property (nonatomic, assign) NSInteger durationActive;
@property (nonatomic, assign) NSInteger durationUnzip;
@property (nonatomic, assign) NSInteger durationDecompressZstd;
@property (nonatomic, assign) NSInteger durationBytepatch;
@property (nonatomic, assign) NSInteger durationZipPatch;

@property (nonatomic, strong) NSDate *startTime;
// 初始化时间，也是这个channel加入更新队列的时间
@property (nonatomic, strong) NSDate *createTime;

- (IESGurdUpdateStageModel *)getStageModel: (BOOL)needCreate
                                   isPatch: (BOOL)isPatch;
- (void)resetDuration;
- (void)putDataToDict:(NSMutableDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
