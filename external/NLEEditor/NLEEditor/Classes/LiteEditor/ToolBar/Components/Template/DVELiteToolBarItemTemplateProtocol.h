//
//  DVELiteToolBarItemTemplateProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVELiteToolBarItemProtocol;

@protocol DVELiteToolBarItemTemplateProtocol <NSObject>

- (NSArray<Class<DVELiteToolBarItemProtocol>> *)barItemClasses;

@end

NS_ASSUME_NONNULL_END
