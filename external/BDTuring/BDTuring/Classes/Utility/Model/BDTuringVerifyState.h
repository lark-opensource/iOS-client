//
//  BDTuringVerifyState.h
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDTuringVerifyModel;

@interface BDTuringVerifyState : NSObject

/// should work with multi thread
@property (atomic, copy) NSDictionary *h5State;///  use for report
@property (nonatomic, assign) BOOL validated;
@property (nonatomic, copy) NSString *subType;

@end

NS_ASSUME_NONNULL_END
