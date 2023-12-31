//
//  DVENLEEditorProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/9/3.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLENativeDefine.h>

NS_ASSUME_NONNULL_BEGIN

@class NLEModel_OC,NLEBranch_OC;
@protocol NLEEditorDelegate, NLEEditor_iOSListenerProtocol;

@protocol DVENLEEditorProtocol <NSObject>

- (void)addDelegate:(id<NLEEditorDelegate>)delegate;

- (void)removeDelegate:(id<NLEEditorDelegate>)delegate;

- (void)addListener:(id<NLEEditor_iOSListenerProtocol>)listener;

- (BOOL)undo;

- (BOOL)redo;

- (BOOL)canUndo;

- (BOOL)canRedo;

- (void)commit;

- (void)commit:(void (^ _Nullable)(NSError *_Nullable error))completion;

- (BOOL)done;

- (BOOL)done:(NSString*)message;

- (NSString *)store;

- (NLEError)restore:(NSString *)jsonString;

- (NLEModel_OC *)nleModel;

- (void)setNleModel:(NLEModel_OC*)nleModel;

- (NLEBranch_OC*)branch;

- (BOOL)gotoCommit:(NSString *)commitID;

@end

NS_ASSUME_NONNULL_END
