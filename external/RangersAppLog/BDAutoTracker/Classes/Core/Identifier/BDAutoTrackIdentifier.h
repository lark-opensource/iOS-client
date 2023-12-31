//
//  BDAutoTrackIdentifier.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/10/10.
//

#import <Foundation/Foundation.h>
#import "BDCommonEnumDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackIdentifier : NSObject

- (instancetype)initWithTracker:(id)tracker;
/*
 *  开启Mock模式、用于新用户模式模拟测试
 */
@property (nonatomic, assign) BOOL mockEnabled;

@property (nonatomic, copy) BDAutoTrackServiceVendor serviceVendor;

- (NSString *)vendorID;

- (NSString *)advertisingID;

- (void)clearIDs;


@end

NS_ASSUME_NONNULL_END
