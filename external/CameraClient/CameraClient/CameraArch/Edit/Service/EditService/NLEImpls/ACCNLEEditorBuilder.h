//
//  ACCNLEEditorBuilder.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/2/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>
NS_ASSUME_NONNULL_BEGIN

@interface ACCNLEEditorBuilder : NSObject <ACCEditSessionBuilderProtocol>
@property (nonatomic, readonly) NLEInterface_OC *nle;
- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
