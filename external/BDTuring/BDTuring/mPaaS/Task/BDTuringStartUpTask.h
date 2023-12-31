//
//  BDTuringStartUpTask.h
//  BDStartUp
//
//  Created by bob on 2020/4/1.
//

#import <BDStartUp/BDStartUpTask.h>
#import "BDTuringDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringConfig, BDTuring;

///
/**
#import <BDStartUp/BDStartUpGaia.h>
#import <BDStartUp/BDTuringStartUpTask.h>
 
BDAppCustomConfigFunction() {
    [BDTuringStartUpTask sharedInstance].xx = xxx;
 }
 */

@interface BDTuringStartUpTask : BDStartUpTask

@property (nonatomic, strong, readonly) BDTuringConfig *config;
@property (nonatomic, strong, readonly, nullable) BDTuring *turing;


+ (instancetype)sharedInstance;

- (void)popVerifyViewWithCallback:(BDTuringVerifyCallback)callback;

@end

NS_ASSUME_NONNULL_END
