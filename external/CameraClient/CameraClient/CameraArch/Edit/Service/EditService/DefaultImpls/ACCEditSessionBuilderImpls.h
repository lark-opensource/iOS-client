//
//  ACCEditSessionBuilderImpls.h
//  AWEStudio-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/13.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel, IESVideoAddEdgeData, IESMMTranscoderParam;

@interface ACCEditSessionBuilderImpls : NSObject <ACCEditSessionBuilderProtocol>
 
- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel isMV:(BOOL)isMV;

@end

NS_ASSUME_NONNULL_END
