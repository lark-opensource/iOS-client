//
//  ACCTextStickerHandlerSpeakerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/5.
//

#import "ACCTextStickerHandlerSpeakerModel.h"

#import <CreativeKit/ACCMacrosTool.h>

@interface ACCTextStickerHandlerSpeakerModel ()

@property (nonatomic, strong, nullable, readwrite) AWETextStickerReadModel *modelBeforeEditing;
@property (nonatomic, strong, nullable, readwrite) AWETextStickerReadModel *modelWhileEditing;

@end

@implementation ACCTextStickerHandlerSpeakerModel

#pragma mark - Public Methods

- (void)updateBeforeEditingWithTextStickerView:(ACCTextStickerView *)editingTextStickerView
{
    _editingTextStickerView = editingTextStickerView;
    _editingTextStickerTimeView = [editingTextStickerView.stickerContainer stickerViewWithContentView:editingTextStickerView];
    AWETextStickerReadModel *model = [editingTextStickerView.textModel.readModel copy];
    if (model == nil) {
        model = [[AWETextStickerReadModel alloc] init];
        model.text = editingTextStickerView.textView.text;
        model.stickerKey = editingTextStickerView.textStickerId;
        model.useTextRead = NO;
        model.audioPath = nil;
        model.soundEffect = nil;
    }
    _modelBeforeEditing = [model copy];
    _modelWhileEditing = [model copy];
}

- (void)updateModelWhileEditing:(NSString *)audioPath speakerID:(NSString *)speakerID
{
    if (ACC_isEmptyString(audioPath)) {
        self.modelWhileEditing.useTextRead = NO;
    } else {
        self.modelWhileEditing.useTextRead = YES;
    }
    self.modelWhileEditing.audioPath = audioPath;
    self.modelWhileEditing.soundEffect = speakerID;
}

- (void)reset
{
    _editingTextStickerView = nil;
    _editingTextStickerTimeView = nil;
    _modelBeforeEditing = nil;
    _modelWhileEditing = nil;
}

#pragma mark - Getters and Setters

- (AWETextStickerReadModel *)modelBeforeEditing
{
    if (_modelBeforeEditing) {
        return [_modelBeforeEditing copy];
    }
    return _modelBeforeEditing;
}

- (AWETextStickerReadModel *)modelWhileEditing
{
    if (_modelWhileEditing) {
        _modelWhileEditing.text = self.editingTextStickerView.textView.text;
    }
    return _modelWhileEditing;
}

@end
