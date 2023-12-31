//
//  BDPTrackEventInfo.h
//  Timor
//
//  Created by 傅翔 on 2019/3/6.
//

#import <Foundation/Foundation.h>
#import "BDPTrackerConstants.h"
#import "BDPUniqueID.h"

NS_ASSUME_NONNULL_BEGIN

/**
 埋点信息对象, 可像MutableDictionary一样使用糖语法 info[@"key"] = value
 */
@interface BDPTrackEventInfo : NSObject <NSCopying>

@property (nonatomic, nullable, copy) NSString *mp_id;
@property (nonatomic, nullable, copy) NSString *mp_name;
@property (nonatomic, nullable, copy) NSString *launch_from;
@property (nonatomic, nullable, copy) NSString *_param_for_special;
@property (nonatomic, nullable, copy) NSString *mp_gid;
@property (nonatomic, nullable, copy) NSString *trace_id;

@property (nonatomic, strong) BDPUniqueID *uniqueID;

@property (nonatomic, nullable, readonly) NSDictionary<NSString *, NSString *> *infoDict;

- (void)setObject:(nullable id)obj forKeyedSubscript:(id<NSCopying>)key;
- (nullable id)objectForKeyedSubscript:(id<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
