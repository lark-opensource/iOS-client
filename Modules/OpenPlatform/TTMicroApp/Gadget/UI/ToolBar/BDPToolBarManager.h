//
//  BDPToolBarManager.h
//  Timor
//
//  Created by 维旭光 on 2019/10/28.
//
//  BDPToolBarView临时统一管理类

#import <Foundation/Foundation.h>
#import "BDPToolBarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPToolBarManager : NSObject

@property (nonatomic, assign) BOOL hidden;

- (void)addToolBar:(BDPToolBarView *)toolBar;

@end

NS_ASSUME_NONNULL_END
