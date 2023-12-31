//
//  DVEVCContextServiceContainer.h
//  NLEEditor
//
//  Created by bytedance on 2021/8/16.
//

#import <Foundation/Foundation.h>
#import <DVEFoundationKit/DVEFoundationInject.h>
#import "DVEVCContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEVCContextServiceContainer : DVEDIStaticContainer

@property (nonatomic, weak) DVEVCContext *vcContext;

@end

NS_ASSUME_NONNULL_END
