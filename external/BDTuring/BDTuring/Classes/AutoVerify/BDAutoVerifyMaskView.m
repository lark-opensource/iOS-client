//
//  BDAutoVerifyMaskView.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/9.
//

#import "BDAutoVerifyMaskView.h"
#import "BDAutoVerify.h"
#import "BDAutoVerifyDataModel.h"
#import "BDAutoVerifyView.h"
#import "BDAutoVerify+Private.h"

@interface BDAutoVerifyMaskView ()

@property (nonatomic, strong) BDAutoVerify *verify;

@property (nonatomic, assign) double touchStartTimeStamp;

@end

@implementation BDAutoVerifyMaskView

- (instancetype)init {
    if (self = [super init]) {
        self.alpha = 1;
        self.userInteractionEnabled = YES;
        self.dataModel = [BDAutoVerifyDataModel new];
    }
    return self;
}

- (instancetype)initWithVerify:(BDAutoVerify *)verify frame:(CGRect)frame {
    self = [self init];
    self.verify = verify;
    self->_type = self.verify.type;
    self.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    return self;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch  = [[touches allObjects] firstObject];
    if ([touch.view isKindOfClass:[self class]]) {
        self.touchStartTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        self.dataModel.force = touch.force;
        self.dataModel.majorRadius = touch.majorRadius;
        self.dataModel.maskViewSize = self.frame.size;
        if (@available(ios 9.1, *)) {
            self.dataModel.clickPoint = [self convertPoint:[touch preciseLocationInView:self] toView:self];
        } else {
            self.dataModel.clickPoint = [self convertPoint:[touch locationInView:self] toView:self];
        }
        self.dataModel.operateDuration = ceil(self.touchStartTimeStamp - self.startTimeStamp);
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    UITouch *touch  = [[touches allObjects] firstObject];
    if ([touch.view isKindOfClass:[self class]]) {
        double touchEndTime = [[NSDate date] timeIntervalSince1970] * 1000;
        self.dataModel.clickDuration = ceil(touchEndTime - self.touchStartTimeStamp);
        [self.verify startAutoVerify];
    }
}


@end
