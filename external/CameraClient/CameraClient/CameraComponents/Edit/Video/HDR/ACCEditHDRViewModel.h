//
//  ACCEditHDRViewModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/7/8.
//

#import <Foundation/Foundation.h>
#import "ACCEditViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditHDRProvideProtocol <NSObject>
@property (nonatomic, strong, readonly) RACSignal *clearHDRSignal;
- (BOOL)enableVideoHDR;//display hdr entrance 
- (void)clearHDR;
@end


@interface ACCEditHDRViewModel : ACCEditViewModel<ACCEditHDRProvideProtocol>

@end

NS_ASSUME_NONNULL_END
