//
//  LarkPasteHook.h
//  LarkMonitor
//
//  Created by sniperj on 2021/10/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarkPasteHook : NSObject

+ (void)swizzleMethod:(Class)_originClass withSel:(SEL)_originSelector exchangeClass:(Class)_newClass newSel:(SEL)_newSelector;

@end

NS_ASSUME_NONNULL_END
