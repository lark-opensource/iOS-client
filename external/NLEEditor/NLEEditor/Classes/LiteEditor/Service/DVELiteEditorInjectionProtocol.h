//
//  DVELiteEditorInjectionProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVELiteBottomFunctionalViewActionProtocol <NSObject>

- (void)bottomFunctionalView:(UIView<DVELiteBottomFunctionalViewActionProtocol> *)view
         didChangeScreenSize:(CGSize)newSize;

@end

@class DVEVCContext;

@protocol DVELiteEditorInjectionProtocol <NSObject>

@optional

- (UIView<DVELiteBottomFunctionalViewActionProtocol> *)bottomFunctionalView;

- (void)willCloseLiteEditor:(DVEVCContext *)vcContext;

@end

NS_ASSUME_NONNULL_END
