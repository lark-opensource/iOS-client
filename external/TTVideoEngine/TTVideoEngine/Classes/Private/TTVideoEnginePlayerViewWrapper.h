//
//  TTVideoEnginePlayerViewWrapper.h
//  TTVideoEngine
//
//  Created by haocheng on 2021/9/22.
//

#pragma once
#import <Foundation/Foundation.h>
#import "TTVideoEngineDualCore.h"
#import "TTVideoEngine.h"
#import "TTVideoEngineLogView.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEnginePlayerViewWrapper : NSObject

@property (nonatomic, assign) TTVideoEnginePlayerType type;
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic, strong) TTVideoEngineLogView *debugView;

- (instancetype)initWithType:(TTVideoEnginePlayerType)type;

@end

NS_ASSUME_NONNULL_END
