//
//  BDXViewContainer.h
//  AFgzipRequestSerializer
//
//  Created by bytedance on 2021/3/3.
//

#import <UIKit/UIKit.h>
#import <BDXServiceCenter/BDXViewContainerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXMonitorProtocol;

@interface BDXViewContainerSerivce : NSObject <BDXViewContainerServiceProtocol>

@end

@interface BDXView : UIView <BDXViewContainerProtocol>

- (id<BDXMonitorProtocol>)lifeCycleTracker;

@property(nonatomic, assign) BOOL isLoading;

@end

NS_ASSUME_NONNULL_END
