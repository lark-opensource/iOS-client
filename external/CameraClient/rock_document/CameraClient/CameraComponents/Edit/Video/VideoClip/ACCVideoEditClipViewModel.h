//
//  ACCVideoEditClipViewModel.h
//  CameraClient-Pods-DouYin
//
//  Created by chengfei xiao on 2020/8/7.
//

#import <Foundation/Foundation.h>
#import "ACCEditViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCEditClipServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCVideoEditClipProvideProtocol <NSObject>
- (void)sendDidFinishClipEditSignal;
- (void)sendWillRemoveAllEditsSignal;
- (void)sendDidRemoveAllEditsSignal;
@end


@interface ACCVideoEditClipViewModel : ACCEditViewModel<ACCEditClipServiceProtocol, ACCVideoEditClipProvideProtocol>

- (void)sendRemoveAllEditsSignal;

@end

NS_ASSUME_NONNULL_END
