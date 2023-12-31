//
//  BDPToolBarManager.m
//  Timor
//
//  Created by 维旭光 on 2019/10/28.
//

#import "BDPToolBarManager.h"

@interface BDPToolBarManager ()

@property (nonatomic, strong) NSPointerArray *toolBars;

@end

@implementation BDPToolBarManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.toolBars = [NSPointerArray weakObjectsPointerArray];
    }
    return self;
}

- (void)addToolBar:(BDPToolBarView *)toolBar {
    [self.toolBars addPointer:(__bridge void * _Nullable)(toolBar)];
}

- (void)setHidden:(BOOL)hidden {
    
    if (hidden != _hidden) {
        [self compact];
        
        _hidden = hidden;
        
        for (BDPToolBarView *toolBar in _toolBars) {
            toolBar.hidden = hidden;
        }
    }
}

- (void)compact {
    // 先add NULL再compact才能清除所有NULL
    [_toolBars addPointer:NULL];
    [_toolBars compact];
}

@end
