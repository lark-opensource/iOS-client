//
//  ACCEditSessionBuilderProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/17.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditSessionWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel, NLEInterface_OC;
@protocol ACCMediaContainerViewProtocol, AWEVideoPublishViewModel;

@protocol ACCEditBuildListener <NSObject>

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession;
@optional
- (void)onNLEEditorInit:(NLEInterface_OC *)editor;
- (void)setupPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel;

@end

@protocol ACCEditSessionProvider <NSObject>

@property (nonatomic, strong, readonly) UIView <ACCMediaContainerViewProtocol> *mediaContainerView;

- (void)addEditSessionListener:(id<ACCEditBuildListener>)listener;

@end

@protocol IESServiceProvider;
@protocol ACCEditSessionBuilderProtocol <ACCEditSessionProvider>

- (ACCEditSessionWrapper *)buildEditSession;

- (void)resetPlayerAndPreviewEdge;
@optional
- (void)updateCanvasContent;
- (void)configResolver:(id<IESServiceProvider>)resolver;
- (void)resetEditSessionWithPublishModel:(AWEVideoPublishViewModel *)publishModel;
- (void)resetPreModel;

@end

NS_ASSUME_NONNULL_END
