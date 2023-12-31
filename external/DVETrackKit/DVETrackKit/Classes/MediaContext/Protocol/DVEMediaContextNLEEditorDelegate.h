//
//  DVEMediaContextNLEEditorDelegate.h
//  DVETrackKit
//
//  Created by bytedance on 2021/9/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NLEModel_OC;
@protocol NLEEditorDelegate, NLEEditor_iOSListenerProtocol;

@protocol DVEMediaContextNLEEditorDelegate <NSObject>

- (void)mediaDelegateAddNLEEditorDelegate:(id<NLEEditorDelegate>)delegate;

- (void)mediaDelegateRemoveNLEEditorDelegate:(id<NLEEditorDelegate>)delegate;

- (void)mediaDelegateAddNLEEditorListener:(id<NLEEditor_iOSListenerProtocol>)listener;

- (void)mediaDelegateCommit;

- (BOOL)mediaDelegateDone;

- (NLEModel_OC *)mediaDelegateNLEModel;

@end

NS_ASSUME_NONNULL_END
