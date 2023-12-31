//
//  HMDTTLeaksFinderRecord.h
//  Heimdallr_Example
//
//  Created by bytedance on 2020/5/29.
//  Copyright © 2020 ghlsb@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Heimdallr/HMDAddressUnit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTHMDLeaksFinderRecord : NSObject

@property (nonatomic, copy) NSString *retainCycle;
@property (nonatomic, copy) NSString *viewStack;
@property (nonatomic, copy) NSString *leaksId;
@property (nonatomic, copy) NSString *cycleKeyClass;
@property (nonatomic, copy) NSString *buildInfo;
@property (nonatomic, copy) NSString *leakSize;
@property (nonatomic, copy) NSString *leakSizeRound;
@property (nonatomic, copy) NSArray<HMDAddressUnit *> *addressList;

// 需要在后台显示的数据
- (NSDictionary *)customData;

@end

NS_ASSUME_NONNULL_END
