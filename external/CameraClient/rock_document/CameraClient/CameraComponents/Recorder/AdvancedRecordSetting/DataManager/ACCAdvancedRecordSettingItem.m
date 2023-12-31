//
//  ACCAdvancedRecordSettingItem.m
//  Indexer
//
//  Created by Shichen Peng on 2021/10/28.
//

#import "ACCAdvancedRecordSettingItem.h"
// CreativeKit
#import <CreativeKit/ACCMacros.h>
// CameraClient
#import <CameraClient/ACCAdvancedRecordSettingConfigManager.h>

typedef void (^ActionWrapper)(BOOL value);

@implementation ACCAdvancedRecordSettingItem

@synthesize cellClass = _cellClass;
@synthesize title = _title;
@synthesize content = _content;
@synthesize needShow = _needShow;
@synthesize switchActionBlock = _switchActionBlock;
@synthesize switchActionBlockWrapper = _switchActionBlockWrapper;
@synthesize segmentActionBlock = _segmentActionBlock;
@synthesize segmentActionBlockWrapper = _segmentActionBlockWrapper;
@synthesize iconImage = _iconImage;
@synthesize switchState = _switchState;
@synthesize touchEnable = _touchEnable;
@synthesize cellType = _cellType;
@synthesize index = _index;
@synthesize itemType = _itemType;
@synthesize trackEventSwitchBlock = _trackEventSwitchBlock;
@synthesize trackEventSegmentBlock = _trackEventSegmentBlock;

- (void)setSwitchActionBlock:(void (^)(BOOL, BOOL))switchActionBlock
{
    @weakify(self);
    self.switchActionBlockWrapper = ^(BOOL state) {
        @strongify(self);
        if (self.switchActionBlock) {
            self.switchActionBlock(state, NO);
        }
        self.switchState = state;
        [ACCAdvancedRecordSettingConfigManager saveSettingBoolValue:state withType:self.itemType];
        if (self.trackEventSwitchBlock) {
            self.trackEventSwitchBlock(state);
        }
    };
    _switchActionBlock = switchActionBlock;
}

- (void)setSegmentActionBlock:(void (^)(NSUInteger, BOOL))segmentActionBlock
{
    @weakify(self);
    self.segmentActionBlockWrapper = ^(NSUInteger index) {
        @strongify(self);
        if (self.segmentActionBlock) {
            self.segmentActionBlock(index, NO);
        }
        self.index = index;
        [ACCAdvancedRecordSettingConfigManager saveSettingIntegerValue:index withType:self.itemType];
        if (self.trackEventSegmentBlock) {
            self.trackEventSegmentBlock(index);
        }
    };
    _segmentActionBlock = segmentActionBlock;
}

@end
