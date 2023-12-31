//
//  IESEffectComposerNodeView.m
//  Pods
//
//  Created by stanshen on 2018/9/29.
//

#import "IESEffectComposerNodeView.h"
#import "IESEffectComposerNodeCollectionViewCell.h"
#import "Masonry.h"

@interface IESEffectComposerNodeView()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) IESComposerModel *composerModel;

@property (nonatomic, strong) UICollectionView *nodePickerView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UISlider *slider;

@end

@implementation IESEffectComposerNodeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.nodePickerView];
        [self addSubview:self.backButton];
    }
    return self;
}

- (UICollectionView *)nodePickerView {
    if (!_nodePickerView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 10.0;
        layout.minimumInteritemSpacing = 10.0;
        CGFloat width = (UIScreen.mainScreen.bounds.size.width - 70) / 5;
        layout.itemSize = CGSizeMake(width, width);
        CGRect frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + 50, self.bounds.size.width, self.bounds.size.height - 50);
        _nodePickerView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        
        _nodePickerView.dataSource = self;
        _nodePickerView.delegate = self;
        [_nodePickerView registerClass:[IESEffectComposerNodeCollectionViewCell class] forCellWithReuseIdentifier:@"IESEffectComposerNodeCollectionViewCell"];
    }
    return _nodePickerView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_backButton setTitle:@"  " forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(onCloseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        _backButton.frame = CGRectMake(0, 0, 50, 50);
    }
    return _backButton;
}

- (UISlider *)slider {
    if (!_slider) {
        _slider = [[UISlider alloc] initWithFrame:CGRectMake(20, self.bounds.origin.y + self.bounds.size.height / 2,
                                                             self.frame.size.width - 40, 20)];
        _slider.maximumValue = 100;
        _slider.minimumValue = 0;
        _slider.value = 30;
        [_slider addTarget:self action:@selector(onSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_slider];
        _slider.hidden = YES;
    }
    return _slider;
}


- (void)onCloseButtonTapped:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(backButtonTappedForComposerNodeView:)]) {
        [self.delegate backButtonTappedForComposerNodeView:self];
    }
}

- (void)onSliderValueChanged:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(composerNodeView:didChangeSliderValue:)]) {
        [self.delegate composerNodeView:self didChangeSliderValue:self.slider.value];
    }
}

- (void)updateWithComposerModel:(IESComposerModel *)model {
    self.composerModel = model;
    IESComposerNode *currentNode = self.composerModel.currentNode;
    switch (currentNode.type) {
        case IESComposerNodeTypeCategory:
        case IESComposerNodeTypeGroup:
        {
            self.slider.hidden = YES;
            [self.nodePickerView reloadData];
        }
            break;
        case IESComposerNodeTypeSiSlider:
        case IESComposerNodeTypeBiSlider:
        {
            self.slider.hidden = NO;
            self.slider.maximumValue = currentNode.maxValue;
            self.slider.minimumValue = currentNode.minValue;
            self.slider.value = currentNode.defaultValue;
            [self.nodePickerView reloadData];
        }
            break;
        default:
            break;
    }
    
    
    
}


#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.composerModel.currentNode.children.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IESComposerNode *node = self.composerModel.currentNode.children[indexPath.row];
    IESEffectComposerNodeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IESEffectComposerNodeCollectionViewCell" forIndexPath:indexPath];
    [cell renderWithTitle:node.uiName];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(composerNodeView:didSelectAtIndexPath:)]) {
        [self.delegate composerNodeView:self didSelectAtIndexPath:indexPath];
    }
}




@end
