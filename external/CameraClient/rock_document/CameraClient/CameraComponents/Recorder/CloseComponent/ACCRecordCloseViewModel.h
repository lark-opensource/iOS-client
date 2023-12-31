//
//  ACCRecordCloseViewModel.h
//  Pods
//
//  Created by liyingpeng on 2020/5/19.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordCloseViewModel : ACCRecorderViewModel

@property (nonatomic, strong, readonly) RACSignal *manullyClickCloseButtonSuccessfullyCloseSignal; // click close button and successfully close record page signal

- (void)manullyClickCloseButtonSuccessfullyClose;

@end

NS_ASSUME_NONNULL_END
