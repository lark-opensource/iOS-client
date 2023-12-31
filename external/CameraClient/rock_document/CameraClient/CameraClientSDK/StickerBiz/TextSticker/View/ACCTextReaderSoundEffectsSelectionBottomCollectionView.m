//
//  ACCTextReaderSoundEffectsSelectionBottomCollectionView.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/18.
//

#import "ACCTextReaderSoundEffectsSelectionBottomCollectionView.h"

#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell.h"
#import "ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel.h"
#import "ACCTextStickerCacheHelper.h"
#import "ACCTextReadingRequestHelper.h"

static CGFloat const kMinimumInteritemSpacing = CGFLOAT_MAX;
static CGFloat const kMinimumLineSpacing = 8.0f;

@interface ACCTextReaderSoundEffectsSelectionBottomCollectionView ()
<
UICollectionViewDelegateFlowLayout,
UICollectionViewDataSource,
AVAudioPlayerDelegate
>

@property (nonatomic, strong) ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel *viewModel;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSIndexPath *lastSelectedIndexPath;

@end

@implementation ACCTextReaderSoundEffectsSelectionBottomCollectionView

- (instancetype)init
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = kMinimumInteritemSpacing;
    layout.minimumLineSpacing = kMinimumLineSpacing;
    self = [super initWithFrame:CGRectZero collectionViewLayout:layout];
    if (self) {
        self.viewModel = [[ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel alloc] init];
        [self p_setupCollectionView];
        [self p_addObservers];
    }
    return self;
}

- (void)dealloc
{
    [[ACCTextReadingRequestHelper sharedHelper] cancelTextReadingRequest];
    [self p_removeObservers];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    UIView *newSuperview = self.superview;
    if (newSuperview == nil) {
        return;
    }
    self.viewModel.audioText = ACCBLOCK_INVOKE(self.getTextReaderModelBlock).text;
    @weakify(self);
    ACCBLOCK_INVOKE(self.showLoadingView);
    NSString *firstSelectedSpeakerID = ACCBLOCK_INVOKE(self.getTextReaderModelBlock).soundEffect; // indicate the speaker that should be selected at the init stage
    if (firstSelectedSpeakerID == nil) {
        firstSelectedSpeakerID = [ACCTextStickerCacheHelper getLastSelectedSpeaker];
    }
    self.viewModel.originalSpeakerID = firstSelectedSpeakerID;
    [self.viewModel fetchTextReaderTimbreListWithCompletion:^(NSError * _Nonnull error) {
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.hideLoadingView);
            [self reloadData];
            if (error) {
                [self collectionView:self didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
                AWELogToolError2(@"reaload data", AWELogToolTagEdit, @"ACCTextReaderSoundEffectsSelectionBottomCollectionView relaod data failed, %@", error.localizedDescription ?: @"");
                return;
            }
            BOOL hasMatchedSpeaker = NO;
            for (NSUInteger i = 0; i < self.viewModel.cellModels.count; i++) {
                ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *cellModel = self.viewModel.cellModels[i];
                if ([cellModel.soundEffect isEqualToString:firstSelectedSpeakerID]) {
                    [self collectionView:self didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                    hasMatchedSpeaker = YES;
                    return;
                }
            }
            if (!hasMatchedSpeaker) {
                [ACCToast() show:@"当前使用音色已被下架"];
                [self collectionView:self didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
            }
        });
    }];
}

#pragma mark - Public Methods

- (void)prepareForClosing
{
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    ACCBLOCK_INVOKE(self.getTextReaderModelBlock).soundEffect = self.viewModel.cellModels[self.viewModel.selectedIndexPath.item].soundEffect;
    self.getTextReaderModelBlock = nil;
}

#pragma mark - Private Methods

- (void)p_setupCollectionView
{
    [self registerClass:[ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell class] forCellWithReuseIdentifier:[ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell identifier]];
    self.delegate = self;
    self.dataSource = self;
    self.backgroundColor = UIColor.clearColor;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
}

- (void)p_setSelectedCell:(NSIndexPath *)indexPath
{
    // get the currently selected and previously selected cells' info
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *currentlySelectedCell;
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *currentlySelectedCellModel;
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *previouslySelectedCell;
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *previouslySelectedCellModel;
    currentlySelectedCell = (ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *)[self cellForItemAtIndexPath:indexPath];
    currentlySelectedCellModel = self.viewModel.cellModels[indexPath.item];
    previouslySelectedCell = (ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *)[self cellForItemAtIndexPath:self.viewModel.selectedIndexPath];
    previouslySelectedCellModel = self.viewModel.cellModels[self.viewModel.selectedIndexPath.item];
    
    // deselect previously selected cell
    [previouslySelectedCell setSelected:NO];
    [previouslySelectedCellModel setSelected:NO];
    [previouslySelectedCellModel setPlaying:NO];
    [previouslySelectedCell configCellWithModel:previouslySelectedCellModel];
    [self reloadItemsAtIndexPaths:@[self.viewModel.selectedIndexPath]];
    
    // select current cell
    [currentlySelectedCell setSelected:YES];
    [currentlySelectedCellModel setSelected:YES];
    [currentlySelectedCell configCellWithModel:currentlySelectedCellModel];
    [self reloadItemsAtIndexPaths:@[indexPath]];
    self.viewModel.selectedIndexPath = indexPath;
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, currentlySelectedCell);
}

- (void)p_addObservers
{
    [self p_removeObservers];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_handleAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_handleAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)p_removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)p_handleAppWillResignActive:(NSNotification*)notification {
    [self.audioPlayer pause];
}
- (void)p_handleAppDidBecomeActive:(NSNotification*)notification {
    [self.audioPlayer play];
}

#pragma mark - Getters and Setters

- (NSString * _Nullable)selectedAudioFilePath
{
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *selectedCellModel = self.viewModel.cellModels[self.viewModel.selectedIndexPath.item];
    if (selectedCellModel.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeNone) {
        return nil;
    } else {
        return selectedCellModel.audioPath;
    }
}

- (NSString * _Nullable)selectedAudioSpeakerID
{
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *selectedCellModel = self.viewModel.cellModels[self.viewModel.selectedIndexPath.item];
    if (selectedCellModel.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeNone) {
        return nil;
    } else {
        return selectedCellModel.soundEffect;
    }
}

- (NSString *)selectedAudioSpeakerName
{
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *selectedCellModel = self.viewModel.cellModels[self.viewModel.selectedIndexPath.item];
    return selectedCellModel.titleString;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.viewModel.cellModels.count;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView
                                   cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:[ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell identifier]
                                                                                                       forIndexPath:indexPath];
    [cell configCellWithModel:self.viewModel.cellModels[indexPath.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kTextReaderSoundEffectsSelectionBottomCollectionViewCellWidth,
                      kTextReaderSoundEffectsSelectionBottomCollectionViewCellHeight);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *textReaderCell = (ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *)cell;
    [textReaderCell updateUIStatus];
}

/// to ensure the previous selected cell being deselected
/// @param collectionView
/// @param indexPath the latest selected cell's indexPath
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // mark the last selected cell
    self.lastSelectedIndexPath = indexPath;
    // get the currently selected cell's info
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *currentlySelectedCellModel;
    currentlySelectedCellModel = self.viewModel.cellModels[indexPath.item];
    
    // if it is a none_speaker, select the cell directly
    if (currentlySelectedCellModel.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeNone) {
        [self p_setSelectedCell:indexPath];
        // disable tts audio
        [self.audioPlayer stop];
        self.audioPlayer = nil;
        ACCBLOCK_INVOKE(self.didSelectSoundEffectCallback, nil, nil);
        return;
    } else { // otherwise, download the audio and then do select the last selected cell
        // 1. download tts audio
        @weakify(self);
        NSString *text = ACCBLOCK_INVOKE(self.getTextReaderModelBlock).text;
        if (ACC_isEmptyString(text)) {
            return;
        }
        [currentlySelectedCellModel fetchTTSAudioWithText:text
                                               completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            @strongify(self);
            if (!self.getTextReaderModelBlock) {
                return;
            }
            if (error) {
                if ([error.domain isEqualToString:@"com.aweme.network.error"]) {
                    [ACCToast() showError:ACCLocalizedString(@"creation_edit_text_reading_Internet_connection_toast", @"No internet connection. Connect to the internet and try again.")];
                } else {
                    [ACCToast() showError:error.localizedDescription];
                }
                AWELogToolError2(@"fetchTTSAudioWithText", AWELogToolTagEdit, @"get tts audio failed, text is: %@, %@", text ?: @"", error.localizedDescription ?: @"");
            }
            // 2. select the last selected cell if it is downloaded
            if (currentlySelectedCellModel.downloadStatus == AWEEffectDownloadStatusDownloaded && self.lastSelectedIndexPath.item == indexPath.item) {
                [self p_setSelectedCell:self.lastSelectedIndexPath];
                [ACCTextStickerCacheHelper updateLastSelectedSpeaker:currentlySelectedCellModel.soundEffect];
                /// play the downloaded tts audio
                if (self.isUsingOwnAudioPlayer) {
                    if (currentlySelectedCellModel.audioPath != nil) {
                        [self.audioPlayer stop];
                        self.audioPlayer.delegate = nil;
                        NSError *playerError = nil;
                        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:currentlySelectedCellModel.audioPath] error:&playerError];
                        if (!self.audioPlayer || playerError) {
                            AWELogToolError2(@"fetchTTSAudioWithText", AWELogToolTagEdit, @"get tts audio failed, text is [%@], %@", text ?: @"", playerError.localizedDescription ?: @"");
                            return;
                        }
                        self.audioPlayer.volume = self.audioPlayer.volume * 4; // the original volume is really low
                        self.audioPlayer.delegate = self;
                        [currentlySelectedCellModel setPlaying:YES];
                        [self reloadItemsAtIndexPaths:@[indexPath]];
                        [self.audioPlayer prepareToPlay];
                        [self.audioPlayer play];
                    }
                }
                ACCBLOCK_INVOKE(self.didSelectSoundEffectCallback, currentlySelectedCellModel.audioPath, currentlySelectedCellModel.soundEffect);
            }
            return;
        }];
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    acc_dispatch_main_async_safe(^{
        [self.audioPlayer stop];
        self.audioPlayer.delegate = nil;
        self.audioPlayer = nil;
        ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *cell = (ACCTextReaderSoundEffectsSelectionBottomCollectionViewCell *)[self cellForItemAtIndexPath:self.viewModel.selectedIndexPath];
        ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *cellModel = self.viewModel.cellModels[self.viewModel.selectedIndexPath.item];
        [cellModel setPlaying:NO];
        [cell updateUIStatus];
    });
}

@end
