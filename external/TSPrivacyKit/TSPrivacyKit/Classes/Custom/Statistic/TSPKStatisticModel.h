//
//  TSPKStatisticModel.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/21.
//

#import <Foundation/Foundation.h>

@interface TSPKStatisticModel : NSObject

@property (nonatomic, copy, nullable) NSString *key;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic, strong, nullable) NSMutableArray *timeDifferenceArray;
@property (nonatomic, strong, nullable) NSMutableDictionary *hostStates;
@property (nonatomic) NSInteger startTime;
@property (nonatomic) NSInteger endTime;
@property (nonatomic) NSInteger timeCountDown;
@property (nonatomic) NSInteger lastEnterBackgroundTime;
@property (nonatomic, strong, nullable) NSMutableArray *bpeaCertToken;
@property (nonatomic, strong, nullable) NSMutableArray *stackIndexArray;
@property (nonatomic, strong, nullable) NSMutableArray<NSArray *> *deduplicationStackArray;
@property (nonatomic, strong, nullable) NSMutableArray<NSString *> *deduplicationStackStringArray;
@property (nonatomic, strong, nullable) NSMutableArray<NSString *> *lastPages;

@end
