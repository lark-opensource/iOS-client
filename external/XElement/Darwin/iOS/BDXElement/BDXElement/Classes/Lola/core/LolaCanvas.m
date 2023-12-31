//
//  LolaCanvas.m
//  AWEAppConfigurations
//
//  Created by chenweiwei.luna on 2020/10/9.
//

#import "LolaCanvas.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import "LolaDrawCommandFactory.h"
#import "LolaDrawContext.h"
#import "LolaDrawCommand.h"

@interface LolaCanvasView ()

@property(nonatomic, strong) CAShapeLayer *shapeLayer;

@property (nonatomic, strong) NSArray <LolaDrawCommand*> *currentDrawCommands;

@property (nonatomic, strong) LolaDrawContext *drawContext;

@end

@implementation LolaCanvasView : UIView

- (instancetype)init
{
    if(self = [super init]) {
        
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)updateCanvas:(NSArray *)commands
{
    self.currentDrawCommands = commands;
    [self setNeedsDisplay];
}

- (void)appendCanvas
{
    
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();

    for (LolaDrawCommand *command in self.currentDrawCommands) {
        [command draw:self.drawContext context:context];
    }
}

@end

@interface LolaCanvas ()

@property(nonatomic, strong) LolaDrawCommandFactory *commandFactory;

@end


@implementation LolaCanvas

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("lola-canvas")
#else
LYNX_REGISTER_UI("lola-canvas")
#endif

- (UIView *)createView {

    self.commandFactory = [LolaDrawCommandFactory new];
    LolaCanvasView *view = [[LolaCanvasView alloc] init];
    view.drawContext = [[LolaDrawContext alloc] initWithTargetUI:self];
    return view;
}

LYNX_UI_METHOD(flush) {
    NSDictionary *rawData = params[@"data"];

    //clean
    [self.commandFactory createCommandsWithData:rawData context:self.view.drawContext isAppend:NO];
    [(LolaCanvasView *)self.view updateCanvas:self.commandFactory.currentDrawCommands];
}

LYNX_UI_METHOD(append) {
    NSDictionary *rawData = params[@"data"];
    [self.commandFactory createCommandsWithData:rawData context:self.view.drawContext isAppend:YES];
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.commandFactory.currentDrawCommands];
    [array addObjectsFromArray:self.commandFactory.appendDrawCommands];
    [(LolaCanvasView *)self.view updateCanvas:array];
}

@end
