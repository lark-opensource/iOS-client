//
//  ACCEditCutMusicServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/12/30.
//

#import <Foundation/Foundation.h>

#ifndef ACCEditCutMusicServiceProtocol_h
#define ACCEditCutMusicServiceProtocol_h

NS_ASSUME_NONNULL_BEGIN

@class ACCCutMusicRangeChangeContext;
@protocol ACCEditCutMusicServiceProtocol <NSObject>

@property (nonatomic, assign, readonly) BOOL isClipViewShowing;

@property (nonatomic, strong, readonly) RACSignal *checkMusicFeatureToastSignal;
@property (nonatomic, strong, readonly) RACSignal *didClickCutMusicButtonSignal;
@property (nonatomic, strong, readonly) RACSignal *didDismissPanelSignal;

@property (nonatomic, strong, readonly) RACSignal<ACCCutMusicRangeChangeContext *> *cutMusicRangeDidChangeSignal;
@property (nonatomic, strong, readonly) RACSignal<ACCCutMusicRangeChangeContext *> *didFinishCutMusicSignal;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCEditCutMusicServiceProtocol_h */
