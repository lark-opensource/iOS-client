//
//  ACCAcousticAlgorithmComponent.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/6/5.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>

NS_ASSUME_NONNULL_BEGIN

#define ACCLoudnessUFLInvalid (0)

typedef NSInteger(^ACCLoudnessLUFSProvider)(void);

@class ACCGroupedPredicate;

/**
 * open Advanced Settings -> Debug Tools -> Acoustic Algorithm Visualization for visualized algorithm state.
 */
@interface ACCAcousticAlgorithmComponent : ACCFeatureComponent

#pragma mark - Acoustic Algorithm

- (void)openAlgorithmsIfNeeded; // update AEC, DA, LE, EB configuration all at once;

#pragma mark Acoustic Echo Canceller
@property (nonatomic, strong, readonly) ACCGroupedPredicate *openAECPredicate; // predicate with the `or` operand;

#pragma mark Delay Ajustment

@property (nonatomic, strong, readonly) ACCGroupedPredicate *openDAPredicate; // predicate with the `or` operand;

#pragma mark Loudness Equalizer
@property (nonatomic, strong, readonly) ACCGroupedPredicate *openLEPredicate; // predicate with the `or` operand;
- (void)registerLUFSProvider:(ACCLoudnessLUFSProvider)provider;
- (void)unregisterLUFProvider:(ACCLoudnessLUFSProvider)provider;

#pragma mark Ear Back
@property (nonatomic, strong, readonly) ACCGroupedPredicate *openEBPredicate; // predicate with the `or` operand;
@property (nonatomic, assign, readonly) BOOL userOpenedEarback;

#pragma mark - Bar Items

@property (nonatomic, strong, readonly) ACCGroupedPredicate *showEBBarItemPredicate;
- (void)updateBarItemsVisibility;

#pragma mark - Force Record Audio

@property (nonatomic, strong, readonly) ACCGroupedPredicate *forceRecordAudioPredicate; // predicate with the `or` operand;
- (void)enableForceRecordAudioIfNeeded;

@end

NS_ASSUME_NONNULL_END
