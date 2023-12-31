//
//  BDTuringUIHandler.h
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDAccountSealDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringUIHandler : NSObject<BDTuringUIHandler>

/// handler to custom alert, you can see BDTuringUIHandler.m to know how to implement it
/// BDTuringUIHandler is a default handler
/// set it to nil if you want to cancel it
@property (nonatomic, weak, nullable) id<BDTuringUIHandler> handler;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
