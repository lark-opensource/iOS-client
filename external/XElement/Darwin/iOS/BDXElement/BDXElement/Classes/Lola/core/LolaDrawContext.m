//
//  LolaDrawContext.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/10/27.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "LolaDrawContext.h"
#import <Lynx/LynxUI.h>

@interface LolaDrawContext()

@property (nonatomic, weak) LynxUI *ui;

@property(nonatomic, strong) NSMutableArray<UIBezierPath *> *paths;


@end

@implementation LolaDrawContext

- (instancetype)initWithTargetUI:(LynxUI *)view
{
    if (self = [super init]) {
        _ui = view;
        _paths = [NSMutableArray array];
    }
    
    return self;
}

- (void)invidate
{
    [_ui.view setNeedsDisplay];
}

- (void)addNewPath:(UIBezierPath *)path
{
    if (!path) {
        return;
    }
    [_paths addObject:path];
}

- (UIBezierPath *)currentPath
{
    if (_paths.count <= 0) {
        return nil;
    }
    
    return _paths.lastObject;
}


//临时代码
- (void)loadImageWithURL:(nonnull NSURL *)url size:(CGSize)targetSize contextInfo:(nullable NSDictionary *)contextInfo completion:(nonnull LolaImageLoadCompletionBlock)completionBlock
{
    [_ui.context.imageFetcher loadImageWithURL:url size:targetSize contextInfo:contextInfo completion:completionBlock];
}


@end
