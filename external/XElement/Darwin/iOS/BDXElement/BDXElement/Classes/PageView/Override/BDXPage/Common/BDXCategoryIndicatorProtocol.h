//
//  BDXCategoryIndicatorProtocol.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/17.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDXCategoryViewDefines.h"
#import "BDXCategoryIndicatorParamsModel.h"

@protocol BDXCategoryIndicatorProtocol <NSObject>


- (void)jx_refreshState:(BDXCategoryIndicatorParamsModel *)model;


- (void)jx_contentScrollViewDidScroll:(BDXCategoryIndicatorParamsModel *)model;


- (void)jx_selectedCell:(BDXCategoryIndicatorParamsModel *)model;

@end
