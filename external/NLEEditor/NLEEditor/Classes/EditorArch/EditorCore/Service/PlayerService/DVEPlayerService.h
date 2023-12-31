//
//  DVEPlayerService.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVEPlayerServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEPlayerService : NSObject <DVEPlayerServiceProtocol>

- (instancetype)initWithNLEInterface:(NLEInterface_OC *)nle;

@end

NS_ASSUME_NONNULL_END
