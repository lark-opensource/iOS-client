//
//  DVELiteToolBarViewModel.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/4.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

@class DVELiteBarComponentModel, DVEVCContext;

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteToolBarViewModel : NSObject

- (instancetype)initWithVCContext:(DVEVCContext *)vcContext;

@property (nonatomic, weak, readonly) DVEVCContext *vcContext;

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *panelWillShowSignal;

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *panelWillDismissSignal;

@property (nonatomic, strong, readonly) RACSignal *itemWillClickedSignal;

- (void)sendPanelWillShowSignalWithPreviewChange:(BOOL)shouldChangePreview;

- (void)sendPanelWillDismissSignalWithPreviewChange:(BOOL)shouldChangePreview;

- (void)sendItemWillClicked;

- (void)addBarItem:(DVELiteBarComponentModel *)item;

- (NSArray<DVELiteBarComponentModel *> *)barModelArray;

@end

NS_ASSUME_NONNULL_END
