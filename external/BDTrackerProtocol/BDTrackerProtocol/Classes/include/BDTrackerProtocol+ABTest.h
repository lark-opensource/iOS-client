//
//  BDTrackerProtocol+ABTest.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/20.
//

#import "BDTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTrackerProtocol (ABTest)


/*
 default use TT, but if you config it to use BD, you can set it.
 or just remove all TT codes.
 if you have both TT and TT, you should work as below
 e.g.
 if ([your getABUseBD]) {
    [BDTrackerProtocol setUseBDTracker];
 } else {
    [BDTrackerProtocol setUseTTTracker];
 }
 /// you have to check which is enabled
 if ([BDTrackerProtocol isBDTrackerEnabled]) {
     /// init BDTracker
 } else {
     /// init TTTracker
 }
 */
+ (void)setBDTrackerEnabled;
+ (void)setTTTrackerEnabled;

/// check BD is work or not
+ (BOOL)isBDTrackerEnabled;

@end

NS_ASSUME_NONNULL_END
