//
//  ACCRecordContainerMode.m
//  CameraClient-Pods-Aweme
//
//  Created by Kevin Chen on 2020/12/21.
//

#import "ACCRecordContainerMode.h"

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>

@interface ACCRecordContainerMode ()

@property (nonatomic, weak) ACCRecordMode *currentMode;

@end

@implementation ACCRecordContainerMode

@synthesize modeId = _modeId;

#pragma mark - override ACCRecordMode

- (NSInteger)realModeId
{
    return _modeId;
}

// 子模式需要暴露的属性需要重写，这里这样让containerMode对SwitchModeService透明

- (NSInteger)modeId {
    return self.currentMode.modeId;
}

- (BOOL)isVideo
{
    return self.currentMode.isVideo;
}

- (BOOL)isPhoto
{
    return self.currentMode.isPhoto;
}

- (BOOL)isMixHoldTapVideo
{
    return self.currentMode.isMixHoldTapVideo;
}

- (BOOL)autoComplete
{
    return self.currentMode.autoComplete;
}

- (NSString *)trackIdentifier
{
    return self.currentMode.trackIdentifier;
}

- (ACCRecordLengthMode)lengthMode
{
    return self.currentMode.lengthMode;
}

- (AWEVideoRecordButtonType)buttonType
{
    return self.currentMode.buttonType;
}

- (ACCServerRecordMode)serverMode
{
    return self.currentMode.serverMode;
}

- (ACCRecordModeShouldShowBlock)shouldShowBlock
{
    return self.currentMode.shouldShowBlock;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    ACCRecordContainerMode *anotherObj = (ACCRecordContainerMode *)object;
    return [self.submodes isEqual:anotherObj.submodes] && [self.submodeTitles isEqual:anotherObj.submodeTitles];
}

#pragma mark - Public

- (void)configWithModesArray:(NSArray<ACCRecordMode *> *)submodes titles:(NSArray<NSString *> *)titles landingMode:(ACCRecordModeIdentifier)modeID defaultModeIndex:(NSInteger)defaultModeIndex
{
    self.defaultIndex = defaultModeIndex;

    self.submodes = submodes;
    self.submodeTitles = titles;
    NSInteger index = NSNotFound;
    for (int i = 0; i < submodes.count; i++) {
        if (submodes[i].modeId == modeID) {
            submodes[i].isInitial = YES;
            index = i;
            break;
        }
    }
    if (index == NSNotFound) {
        index = defaultModeIndex;
    }
    self.currentIndex = index;
    self.currentMode = [submodes acc_objectAtIndex:index];
}

- (void)setCurrentMode:(ACCRecordMode *)currentMode
{
    NSInteger index = [self.submodes indexOfObject:currentMode];
    if (index != NSNotFound) {
        _currentIndex = index;
        _currentMode = [self.submodes acc_objectAtIndex:index];
    }
}

#pragma mark - Getter & Setter

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    self.currentMode = [self.submodes acc_objectAtIndex:currentIndex];
    _currentIndex = currentIndex;
}

@end
