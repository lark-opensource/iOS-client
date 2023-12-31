//
//  BDDebugFeedTuring.h
//  BDStartUp
//
//  Created by bob on 2020/4/1.
//

#import <BDDebugTool/BDDebugFeedModel.h>

NS_ASSUME_NONNULL_BEGIN

@class BDDebugSectionModel, BDTuringConfig, BDTuring;

@interface BDDebugFeedTuring : BDDebugFeedModel

@property (nonatomic, strong, readonly) BDTuringConfig *config;
@property (nonatomic, strong, readonly) BDTuring *turing;

@property (nonatomic, strong, nullable) NSArray<BDDebugSectionModel *> *sealFeed;
@property (nonatomic, strong, nullable) NSArray<BDDebugSectionModel *> *identityFeed;
@property (nonatomic, strong, nullable) NSArray<BDDebugSectionModel *> *themeFeed;
@property (nonatomic, strong, nullable) NSArray<BDDebugSectionModel *> *parameterFeed;
@property (nonatomic, strong, nullable) NSArray<BDDebugSectionModel *> *autoverifyFeed;
@property (nonatomic, strong, nullable) NSArray<BDDebugSectionModel *> *lynxFeed;
@property (nonatomic, strong, nullable) NSArray<BDDebugSectionModel *> *h5bridgeFeed;
@property (nonatomic, strong, nullable) NSArray<BDDebugSectionModel *> *twiceVerifyFeed;

+ (instancetype)sharedInstance;

- (void)updateSettings;

@end

NS_ASSUME_NONNULL_END
