//
//  CJCouterLabel.m
//  CJPay
//
//  Created by wangxiaohong on 2020/7/15.
//

#import "CJPayCounterLabel.h"
#import "CJPayUIMacro.h"


typedef void(^CJFormatNumberBlock)(CGFloat currentNumber);

@interface CJPayCounterLabel()
/** 定时器*/
@property (nonatomic, strong) CADisplayLink *timer;
/** 开始的数字*/
@property (nonatomic, assign) CGFloat starNumber;
/** 结束的数字*/
@property (nonatomic, assign) CGFloat endNumber;

/** 动画的总持续时间*/
@property (nonatomic, assign) CFTimeInterval durationTime;

/** 记录上一帧动画的时间*/
@property (nonatomic, assign) CFTimeInterval lastTime;

/** 记录动画已持续的时间*/
@property (nonatomic, assign) CFTimeInterval progressTime;

/** 获取当前数字的Block*/
@property (nonatomic, copy) CJFormatNumberBlock formatNumberBlock;

@end


@implementation CJPayCounterLabel

- (void)cj_fromNumber:(CGFloat)startNumber
             toNumber:(CGFloat)endNumber
             duration:(CFTimeInterval)duration
               format:(CJFormatBlock)format
{
    @CJWeakify(self)
    [self p_fromNumber:startNumber toNumber:endNumber duration:duration formatNumberBlock:^(CGFloat currentNumber) {
        @CJStrongify(self)
        format ? self.text = format(currentNumber) : nil ;
    }];
}

- (void)cj_fromNumber:(CGFloat)startNumber
             toNumber:(CGFloat)endNumber
             duration:(CFTimeInterval)duration
     attributedFormat:(CJAttributedFormatBlock)format
{
    @CJWeakify(self)
    [self p_fromNumber:startNumber toNumber:endNumber duration:duration formatNumberBlock:^(CGFloat currentNumber) {
        @CJStrongify(self)
        format ? self.attributedText = format(currentNumber) : nil ;
    }];
}

- (void)p_fromNumber:(CGFloat)starNumer
            toNumber:(CGFloat)endNumber
            duration:(CFTimeInterval)durationTime
   formatNumberBlock:(CJFormatNumberBlock)formatNumberBlock
{
    // 开始前清空定时器
    [self p_cleanTimer];
    
    // 初始化相关变量
    self.starNumber = starNumer;
    self.endNumber = endNumber;
    self.durationTime = durationTime;
    self.formatNumberBlock = formatNumberBlock;
    
    // 如果开始数字与结束数字相等
    if (starNumer == endNumber) {
        [self p_cleanTimer];
        self.formatNumberBlock(self.endNumber);
        return;
    }
    
    // 记录定时器运行前的时间
    _lastTime = CACurrentMediaTime();
    
    // 实例化定时器
    _timer = [CADisplayLink displayLinkWithTarget:[BTDWeakProxy proxyWithTarget:self] selector:@selector(p_changeNumber)];
    [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
}

- (void)p_changeNumber
{
    // 1.记录当前动画开始的时间
    CFTimeInterval thisTime = CACurrentMediaTime();
    // 2.计算动画已持续的时间量
    _progressTime = _progressTime + (thisTime - _lastTime);
    // 3.准备下一次的计算
    _lastTime = thisTime;
    
    if (_progressTime >= _durationTime) {
        [self p_cleanTimer];
        self.formatNumberBlock(self.endNumber);
        return;
    }
    self.formatNumberBlock([self p_computeNumber]);
}

/**
 计算数字
 */
- (CGFloat)p_computeNumber
{
    CGFloat percent = _progressTime / _durationTime;
    return _starNumber + ([self p_bufferFunctionEaseInOut:percent] * (_endNumber - _starNumber));
}

/**
 清除定时器
 */
- (void)p_cleanTimer
{
    if (!_timer) {return;}
    [_timer invalidate];
    _timer = nil;
    _progressTime = 0;
}


- (CGFloat)p_bufferFunctionEaseInOut:(CGFloat)p
{
    if(p == 0.0 || p == 1.0) return p;
    
    if(p < 0.5) {
        return 0.5 * pow(2, (20 * p) - 10);
    } else {
        return -0.5 * pow(2, (-20 * p) + 10) + 1;
    }
}


@end
