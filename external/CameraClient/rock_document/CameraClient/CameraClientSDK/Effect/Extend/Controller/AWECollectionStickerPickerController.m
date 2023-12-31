//
//  AWECollectionStickerPickerController.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/14.
//

#import "AWECollectionStickerPickerController.h"
#import "AWEAutoresizingCollectionView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStickerPickerStickerCell.h"
#import "AWEStickerDownloadManager.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <Masonry/Masonry.h>
#import <KVOController/KVOController.h>


@interface AWECollectionStickerPickerController () <UICollectionViewDataSource, UICollectionViewDelegate, AWEStickerDownloadObserverProtocol>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong, readwrite) AWECollectionStickerPickerModel *model;

@end

@implementation AWECollectionStickerPickerController

#pragma mark - Life Cycle

- (instancetype)initWithStickers:(NSArray<IESEffectModel *> *)stickers currentSticker:(IESEffectModel * _Nullable)currentSticker
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _model = [[AWECollectionStickerPickerModel alloc] init];
        _model.stickers = stickers;
        _model.currentSticker = currentSticker;
        @weakify(self);
        [self.KVOController observe:_model
                            keyPath:FBKVOKeyPath(_model.currentSticker)
                            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                              block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            @strongify(self);
            [self scrollSelectedToCenter];
            IESEffectModel *oldProp = [change acc_objectForKey:NSKeyValueChangeOldKey ofClass:[IESEffectModel class]];;
            IESEffectModel *newProp = [change acc_objectForKey:NSKeyValueChangeNewKey ofClass:[IESEffectModel class]];;
            [self executeSelectAnimationWithOldProp:oldProp newProp:newProp];
        }];
        [[AWEStickerDownloadManager manager] addObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[AWEStickerDownloadManager manager] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(54, 54);
    flowLayout.minimumLineSpacing = 10;
    flowLayout.minimumInteritemSpacing = 7.5;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 16, 0, 16);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView = [[AWEAutoresizingCollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    self.collectionView = collectionView;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.backgroundColor = [UIColor clearColor];
    [collectionView registerClass:[AWEStickerPickerStickerCell class] forCellWithReuseIdentifier:@"cell"];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundView = [[UIView alloc] init];
    collectionView.backgroundView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer3);
    collectionView.backgroundView.layer.cornerRadius = 9;
    
    [self.view addSubview:collectionView];
    
    ACCMasMaker(collectionView, {
        make.edges.equalTo(self.view);
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self scrollSelectedToCenter];
}

#pragma mark - Utils

- (void)scrollSelectedToCenter
{
    if (self.model.currentSticker) {
        NSInteger index = [self.model.stickers indexOfObject:self.model.currentSticker];
        if (index != NSNotFound) {
            NSIndexPath *selected = [NSIndexPath indexPathForItem:index inSection:0];
            self.selectedIndexPath = selected;
            [self.collectionView layoutIfNeeded];
            [self.collectionView scrollToItemAtIndexPath:selected atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }
    }
}

- (void)executeSelectAnimationWithOldProp:(IESEffectModel *)oldProp newProp:(IESEffectModel *)newProp
{
    if (oldProp == newProp) {
        return;
    }
    NSInteger oldIndex = [self.model.stickers indexOfObject:oldProp];
    AWEStickerPickerStickerBaseCell *oldCell = nil;
    if (oldIndex != NSNotFound) {
        oldCell = (AWEStickerPickerStickerBaseCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:oldIndex inSection:0]];
    }
    NSInteger newIndex = [self.model.stickers indexOfObject:newProp];
    AWEStickerPickerStickerBaseCell *newCell = nil;
    if (newIndex != NSNotFound) {
        newCell = (AWEStickerPickerStickerBaseCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:newIndex inSection:0]];
    }
    [oldCell setStickerSelected:NO animated:NO];
    [newCell setStickerSelected:YES animated:YES];
}

#pragma mark - Protocol

#pragma mark AWEStickerDownloadObserverProtocol

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFinishDownloadSticker:(IESEffectModel *)sticker {
    if (sticker && self.model.stickerWillSelect && [sticker.effectIdentifier isEqualToString:self.model.stickerWillSelect.effectIdentifier]) {
        self.model.currentSticker = sticker;
        if ([self.delegate respondsToSelector:@selector(collectionStickerPickerController:didSelectSticker:)]) {
            [self.delegate collectionStickerPickerController:self didSelectSticker:sticker];
        }
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFailDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error
{
    if (sticker && self.model.stickerWillSelect && [sticker.effectIdentifier isEqualToString:self.model.stickerWillSelect.effectIdentifier]) {
        if ([self.delegate respondsToSelector:@selector(collectionStickerPickerController:didFailedLoadSticker:error:)]) {
            [self.delegate collectionStickerPickerController:self didFailedLoadSticker:sticker error:error];
        }
    }
}

#pragma mark UICollectionViewDataSource & UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.model.stickers.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AWEStickerPickerStickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    IESEffectModel *stickerModel = [self.model.stickers objectAtIndex:indexPath.item];
    IESEffectModel *currentSticker = self.model.currentSticker;
    cell.sticker = stickerModel;
    [cell setStickerSelected:[currentSticker.effectIdentifier isEqualToString:stickerModel.effectIdentifier] animated:NO];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
    IESEffectModel *sticker = [self.model.stickers objectAtIndex:indexPath.item];
    if (sticker == self.model.currentSticker) {
        // already selected, do nothing
    } else {
        self.model.stickerWillSelect = sticker;
        if ([self.delegate respondsToSelector:@selector(collectionStickerPickerController:willSelectSticker:atIndexPath:)]) {
            [self.delegate collectionStickerPickerController:self willSelectSticker:sticker atIndexPath:indexPath];
        }

        if (sticker.downloaded) {
            self.model.currentSticker = sticker;
            if ([self.delegate respondsToSelector:@selector(collectionStickerPickerController:didSelectSticker:)]) {
                [self.delegate collectionStickerPickerController:self didSelectSticker:sticker];
            }
        } else {
            [[AWEStickerDownloadManager manager] downloadStickerIfNeed:sticker];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    IESEffectModel *sticker = [self.model.stickers objectAtIndex:indexPath.item];
    
    AWEStickerPickerStickerBaseCell *currentCell = (AWEStickerPickerStickerBaseCell *)cell;
    if (currentCell.stickerSelected != [sticker.effectIdentifier isEqualToString:self.model.currentSticker.effectIdentifier]) {
        [currentCell setStickerSelected:[sticker.effectIdentifier isEqualToString:self.model.currentSticker.effectIdentifier] animated:NO];
    }
    
    // Call delegate will display the sticker.
    if ([self.delegate respondsToSelector:@selector(collectionStickerPickerController:willDisplaySticker:atIndexPath:)]) {
        [self.delegate collectionStickerPickerController:self willDisplaySticker:sticker atIndexPath:indexPath];
    }
}

@end
