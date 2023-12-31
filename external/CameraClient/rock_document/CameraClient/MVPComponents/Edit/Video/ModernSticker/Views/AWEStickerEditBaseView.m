//
//  AWEStickerEditBaseView.m
//  Pods
//
//  Created by li xingdong on 2019/5/5.
//

#import "AWEStickerEditBaseView.h"

@interface AWEStickerEditBaseView()

//backup
@property (nonatomic, strong, readwrite) AWEInteractionStickerLocationModel *backupStickerLocation;
@property (nonatomic, assign, readwrite) CGPoint backupCenter;
@property (nonatomic, assign, readwrite) CGAffineTransform backupTransform;

@end

@implementation AWEStickerEditBaseView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (void)backupLocation
{
    self.backupCenter = self.center;
    self.backupTransform = self.transform;
    self.backupStickerLocation = [self.stickerLocation copy];
}

#pragma mark - Getter/Setter

- (void)setRealStartTime:(CGFloat)realStartTime
{
    _realStartTime = realStartTime;
    _finalStartTime = realStartTime;
}

- (void)setRealDuration:(CGFloat)realDuration
{
    _realDuration = realDuration;
    _finalDuration = realDuration;
}

- (AWEInteractionStickerLocationModel *)stickerLocation
{
    if (!_stickerLocation) {
        _stickerLocation = [[AWEInteractionStickerLocationModel alloc] init];
        _stickerLocation.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    }
    return _stickerLocation;
}

@synthesize finalDuration = _finalDuration;

@synthesize finalStartTime = _finalStartTime;

@synthesize realDuration = _realDuration;

@synthesize realStartTime = _realStartTime;

@end
