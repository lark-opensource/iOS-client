//
//  BDAutoTrackBatchData.h
//  Applog
//
//  Created by bob on 2019/2/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackBatchData : NSObject


@property (nonatomic, assign) NSInteger source;
@property (nonatomic, assign) BOOL autoTrackEnabled;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray *> *realSentData;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray *> *sendingTrackData;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray *> *sendingTrackID;

@property (nonatomic, assign) NSTimeInterval sendTime;

@property (nonatomic, copy, nullable) NSString *ssID;
@property (nonatomic, copy, nullable) NSString *userUniqueID;
@property (nonatomic, copy, nullable) NSString *userUniqueIDType;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *tempTrackDatas;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *tempTrackIDs;

@property (nonatomic, assign) NSUInteger maxEventCount;

- (void)filterData;

- (void)checkSendData:(NSString *)ssid;

@end

@interface BDAutoTrackBatchItem : NSObject

@property (nonatomic, copy) NSArray *trackData;
@property (nonatomic, copy) NSArray *trackID;

@end

NS_ASSUME_NONNULL_END
