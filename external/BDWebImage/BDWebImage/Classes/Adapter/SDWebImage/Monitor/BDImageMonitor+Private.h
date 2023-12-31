//
//  BDImageMonitor+Private.h
//  BDWebImage
//
//  Created by fengyadong on 2017/12/6.
//

#import "BDImageMonitor.h"

@interface BDImageMonitor ()

@property (nonatomic, copy, readwrite) NSString *module;
@property (nonatomic, copy, readwrite) NSString *action;

- (instancetype)initWithModule:(NSString *)module action:(NSString *)action;

@end
