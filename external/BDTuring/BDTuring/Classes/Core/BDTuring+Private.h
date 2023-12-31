//
//  BDTuring+Private.h
//  BDTuring
//
//  Created by bob on 2020/3/2.
//

#import "BDTuring.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringConfig, BDTuringSettings, BDTuringVerifyView, BDTuringVerifyModel;


@interface BDTuring (Private)

@property (nonatomic, assign) BOOL isShowVerifyView;
@property (nonatomic, strong) BDTuringConfig *config;
@property (nonatomic, strong) BDTuringSettings *settings;
@property (nonatomic, strong, nullable) BDTuringVerifyView *verifyView;

@property (nonatomic, strong, nullable) BDTuringVerifyView *autoVerifyView;

@property (nonatomic, assign) BOOL preloadVerifyViewReady;
@property (nonatomic, strong, nullable) BDTuringVerifyView *preloadVerifyView;
@property (nonatomic, strong) NSLock *callbackLock;

@end

NS_ASSUME_NONNULL_END
