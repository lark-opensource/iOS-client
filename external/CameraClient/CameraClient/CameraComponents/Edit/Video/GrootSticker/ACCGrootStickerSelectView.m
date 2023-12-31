//
//  ACCGrootStickerSelectView.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/17.
//

#import "ACCGrootStickerSelectView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import "UIImage+ACCUIKit.h"
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCGrootCollectionViewFlowLayout : UICollectionViewFlowLayout

@end

@implementation ACCGrootCollectionViewFlowLayout

-(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *arr = [super layoutAttributesForElementsInRect:rect];
    CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.bounds.size.width/2.0f;
    for (UICollectionViewLayoutAttributes *attributes in arr) {
        CGFloat distance = fabs(attributes.center.x - centerX);
        CGFloat apartScale = distance/self.collectionView.bounds.size.width;
        CGFloat scale = fabs(cos(apartScale * M_PI/4));
        attributes.transform = CGAffineTransformMakeScale(1.0, scale);
    }
    return arr;
}

- (NSArray *)getCopyOfAttributes:(NSArray *)attributes
{
    NSMutableArray *copyArr = [NSMutableArray new];
    for (UICollectionViewLayoutAttributes *attribute in attributes) {
        [copyArr acc_addObject:[attribute copy]];
    }
    return copyArr;
}

-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return true;
}

@end


@interface ACCGrootStickerSelectCell  ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) ACCGrootDetailsStickerModel *model;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UILabel *grootHashtagLabel;
@property (nonatomic, strong) UIImageView *grootImageView;
@property (nonatomic, strong) UILabel *speciesNameLabel;
@property (nonatomic, strong) UILabel *categoryNameLabel;
@property (nonatomic, strong) UILabel *commonNamelabel;
@property (nonatomic, strong) UILabel *similarityLabel;

@end

@implementation ACCGrootStickerSelectCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return  self;
}

- (void)setupUI {
    self.contentView.userInteractionEnabled = YES;
    self.contentView.layer.cornerRadius = 10.f;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    self.grootImageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.cornerRadius = 8.f;
        imageView.layer.masksToBounds = YES;
        [self.contentView addSubview:imageView];
        ACCMasMaker(imageView, {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(3, 3, 3, 3));
        });
        imageView;
    });
        
    self.gradientLayer = ({
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[
        (__bridge id)[UIColor blackColor].CGColor,
        (__bridge id)[UIColor clearColor].CGColor
        ];
        gradientLayer.startPoint = CGPointMake(0, 1);
        gradientLayer.endPoint = CGPointMake(0, 0);
        CGSize size = [ACCGrootStickerSelectView adaptionCollectionViewSize];
        gradientLayer.frame = CGRectMake(0, size.height - 151, size.width, 150);
        [self.grootImageView.layer addSublayer:gradientLayer];
        gradientLayer;
    });
    
    self.speciesNameLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium];
        label.adjustsFontSizeToFitWidth = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@17.5);
            make.right.equalTo(self.contentView.mas_right).inset(17.5);
            make.height.equalTo(@24);
            make.bottom.equalTo(self.contentView.mas_bottom).inset(58);
        });
        label;
    });
 
    self.grootHashtagLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.adjustsFontSizeToFitWidth = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.numberOfLines = 0;
        label.textColor = [ACCResourceColor(ACCUIColorConstTextInverse) colorWithAlphaComponent:0.5];
        NSString *grootTagString = [NSString stringWithFormat:@"添加 #求高手鉴定 话题，让更多人看到你的动植物视频，有机会获得专家鉴定"];
        NSMutableAttributedString *attGrootTagString = [[NSMutableAttributedString alloc] initWithString:grootTagString];
        NSDictionary *dic = @{
            NSFontAttributeName : [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular],
            NSForegroundColorAttributeName : [ACCResourceColor(ACCUIColorConstTextInverse) colorWithAlphaComponent:0.5]
        };
        [attGrootTagString addAttributes:dic range:NSMakeRange(0, grootTagString.length)];
        dic = @{
            NSFontAttributeName : [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular],
            NSForegroundColorAttributeName : ACCResourceColor(ACCUIColorConstTextInverse)
        };
        [attGrootTagString addAttributes:dic range:[grootTagString rangeOfString:@"#求高手鉴定"]];
        label.attributedText = attGrootTagString;
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@17.5);
            make.right.equalTo(self.contentView.mas_right).inset(17.5);
            make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(6);
            make.bottom.equalTo(self.contentView.mas_bottom).lessThanOrEqualTo(@5);
        });
        label;
    });
    
    self.categoryNameLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        label.adjustsFontSizeToFitWidth = YES;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        label.layer.cornerRadius = 3.0f;
        label.layer.masksToBounds = YES;
        [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@17.5);
            make.height.equalTo(@20);
            make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(2);
        });
        label;
    });
    
    self.commonNamelabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        label.layer.cornerRadius = 3.0f;
        label.layer.masksToBounds = YES;
        label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(self.categoryNameLabel.mas_right).offset(4);
            make.height.equalTo(@20);
            make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(2);
        });
        label;
    });
    
    self.similarityLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [ACCResourceColor(ACCUIColorConstTextInverse) colorWithAlphaComponent:0.5];
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@17.5);
            make.right.equalTo(self.contentView).inset(5);
            make.height.equalTo(@14);
            make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(25);
        });
        label;
    });
}

- (UIImage *)placeholderImage {
    if (!_placeholderImage) {
        _placeholderImage = [UIImage acc_imageWithColor:[[UIColor blackColor] colorWithAlphaComponent:0.15] size:CGSizeMake(1, 1)];
    }
    return _placeholderImage;
}

- (void)configGrootStickerModel:(ACCGrootDetailsStickerModel *)model grootModels:(NSArray<ACCGrootDetailsStickerModel *> *)models {
    self.model = model;
    if (model.isDummy) {
        if (models.count > 1) {
            self.speciesNameLabel.text = @"都不是，求高手鉴定";
        } else {
            self.speciesNameLabel.text = @"求高手鉴定";
        }

        NSDictionary *placeHolderImageDic = ACCConfigDict(kConfigString_dynamic_groot_placeholder_image_url);
        NSArray *hashtagPlaceholderArray = [placeHolderImageDic acc_arrayValueForKey:@"hashtag_placeholder" defaultValue:@[]];
        [ACCWebImage() imageView:self.grootImageView setImageWithURLArray:hashtagPlaceholderArray placeholder:self.placeholderImage];
        self.categoryNameLabel.hidden = YES;
        self.commonNamelabel.hidden = YES;
        self.similarityLabel.hidden = YES;
        self.grootHashtagLabel.hidden = NO;
    } else {
        NSDictionary *placeHolderImageDic = ACCConfigDict(kConfigString_dynamic_groot_placeholder_image_url);
        NSArray *speciesPlaceholderArray = [placeHolderImageDic acc_arrayValueForKey:@"species_placeholder" defaultValue:@[]];
        if (!ACC_isEmptyString(model.baikeHeadImage)) {
            NSMutableArray *imageUrlArray = [@[model.baikeHeadImage] mutableCopy];
            [imageUrlArray addObjectsFromArray:speciesPlaceholderArray ?: @[]];
            [ACCWebImage() imageView:self.grootImageView
                setImageWithURLArray:[imageUrlArray copy]
                         placeholder:self.placeholderImage];
        } else {
            [ACCWebImage() cancelImageViewRequest:self.grootImageView];
            [ACCWebImage() imageView:self.grootImageView setImageWithURLArray:speciesPlaceholderArray placeholder:self.placeholderImage];
        }
        
        self.speciesNameLabel.text = model.speciesName ?: @"";
        self.grootHashtagLabel.hidden = YES;
        NSString *categoryName = model.categoryName;
        if (!ACC_isEmptyString(categoryName)) {
            self.categoryNameLabel.hidden = NO;
            self.categoryNameLabel.text = categoryName;
            CGRect categoryNameRect = [categoryName boundingRectWithSize:CGSizeMake(200, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular]} context:nil];
            ACCMasUpdate(self.categoryNameLabel, {
                make.width.mas_equalTo(categoryNameRect.size.width + 8);
                make.right.lessThanOrEqualTo(self.contentView.mas_right).priorityHigh();
            });
        } else {
            self.categoryNameLabel.hidden = YES;
        }
        
        NSString *commonName = model.commonName;
        if (!ACC_isEmptyString(commonName)) {
            self.commonNamelabel.hidden = NO;
            commonName = [NSString stringWithFormat:@"俗名%@", commonName];
            self.commonNamelabel.text = commonName;
            CGRect commonNamelabelRect = [commonName boundingRectWithSize:CGSizeMake(200, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular]} context:nil];
            ACCMasUpdate(self.commonNamelabel, {
                make.width.mas_equalTo(commonNamelabelRect.size.width + 8);
                make.right.lessThanOrEqualTo(self.contentView.mas_right).priorityHigh();
            });
        } else {
            self.commonNamelabel.hidden = YES;
        }
   
        if (model.prob) {
            self.similarityLabel.hidden = NO;
            double similarity = [model.prob doubleValue] * 100;
            NSString *similarityString = [NSString stringWithFormat:@"相似度 %.1f%%", similarity];
            self.similarityLabel.text = similarityString;
        } else {
            self.similarityLabel.hidden = YES;
        }
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.contentView.layer.borderWidth = 2.0;
        self.contentView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
    } else {
        self.contentView.layer.borderWidth = 0;
        self.contentView.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

@end

@interface ACCGrootStickerSelectView () <UICollectionViewDelegate,UICollectionViewDataSource, UITextViewDelegate>

@property (nonatomic, strong) NSArray<ACCGrootDetailsStickerModel *> *grootDetailsModels;
@property (nonatomic, assign) BOOL allowResearch;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger p_currentIndex;
@property (nonatomic, assign) CGFloat p_dragStartX;
@property (nonatomic, assign) CGFloat p_dragEndX;
@property (nonatomic, weak) id<ACCGrootStickerSelectViewDelegate> delegate;

@property (nonatomic, strong) UILabel *selectTipLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *allowResearchButton;

@end

@implementation ACCGrootStickerSelectView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

-(void)setupUI {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10, 10)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
    
    ACCGrootCollectionViewFlowLayout *layout = [[ACCGrootCollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 14;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.pagingEnabled = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[ACCGrootStickerSelectCell class] forCellWithReuseIdentifier:NSStringFromClass(ACCGrootStickerSelectCell.class)];
    [self addSubview:self.collectionView];

    CGSize size = [ACCGrootStickerSelectView adaptionCollectionViewSize];
    [self.collectionView setFrame:CGRectMake(0, 52, ACC_SCREEN_WIDTH, size.height + 2)];
    
    self.selectTipLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium];
        label.adjustsFontSizeToFitWidth = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        [self addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@16);
            make.right.equalTo(self.mas_right).inset(40);
            make.height.equalTo(@24);
            make.top.equalTo(self.mas_top).inset(16);
        });
        label;
    });
    
    self.closeButton = ({
        UIButton *button = [[UIButton alloc] init];
        [button setImage:ACCResourceImage(@"icon_album_first_creative_close") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didClickCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        ACCMasMaker(button, {
            make.centerY.equalTo(self.selectTipLabel);
            make.right.equalTo(self).inset(8);
            make.height.width.mas_equalTo(32);
        });
        button;
    });
    self.closeButton.accessibilityLabel = @"关闭";
    
    self.saveButton = ({
        ACCAnimatedButton *saveButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [self addSubview:saveButton];
        saveButton.layer.cornerRadius = 2.0;
        saveButton.layer.masksToBounds = YES;
        [saveButton.titleLabel setFont:[ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium]];
        [saveButton setTitle: @"确定" forState:UIControlStateNormal];
        [saveButton setBackgroundColor:ACCResourceColor(ACCColorPrimary)];
        [saveButton addTarget:self action:@selector(didClickedSaveButton:) forControlEvents:UIControlEventTouchUpInside];
        ACCMasMaker(saveButton, {
            make.top.equalTo(self.collectionView.mas_bottom).offset(19);
            make.height.equalTo(@(44));
            make.left.equalTo(@(20));
            make.right.equalTo(@(-20));
        });
        saveButton;
    });
    
    UIView *containerView = [[UIView alloc] init];
    [self addSubview:containerView];
    ACCMasMaker(containerView, {
        make.top.equalTo(self.saveButton.mas_bottom).offset(16);
        make.centerX.equalTo(self);
        make.width.equalTo(@292);
        make.height.equalTo(@20);
    });
    
    self.allowResearchButton = ({
        UIButton *allowResearchButton = [[UIButton alloc] init];
        [allowResearchButton addTarget:self action:@selector(didClickAllowResearchButton:) forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:allowResearchButton];
        ACCMasMaker(allowResearchButton, {
            make.left.equalTo(containerView).offset(0);
            make.top.equalTo(containerView).offset(2);
            make.width.height.equalTo(@16);
        });
        allowResearchButton;
    });
    
    if (self.allowResearch) {
        self.allowResearchButton.accessibilityLabel = @"勾选按钮，已勾选";
    } else {
        self.allowResearchButton.accessibilityLabel = @"勾选按钮，未勾选";
    }

    UILabel *grootTipsLabel = [[UILabel alloc] init];
    grootTipsLabel.text = @"愿意通过抖音通知了解动植物相关公益项目";
    grootTipsLabel.adjustsFontSizeToFitWidth = YES;
    grootTipsLabel.font = [ACCFont() systemFontOfSize:14 weight:ACCFontWeightRegular];
    grootTipsLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
    [containerView addSubview:grootTipsLabel];
    ACCMasMaker(grootTipsLabel, {
        make.left.equalTo(self.allowResearchButton.mas_right).offset(6);
        make.top.equalTo(containerView).offset(0);
        make.height.equalTo(@20);
        make.width.equalTo(@(266));
    });
}

- (void)configData:(NSArray<ACCGrootDetailsStickerModel *> *)models selectedModel:(ACCGrootDetailsStickerModel *)selectedModel allowResearch:(BOOL)allowResearch delegate:(id<ACCGrootStickerSelectViewDelegate>)delegate {
    self.delegate = delegate;
    NSMutableArray *selectModels = [models mutableCopy] ?:  [@[] mutableCopy];
    ACCGrootDetailsStickerModel *dummyModel = [[ACCGrootDetailsStickerModel alloc] init];
    dummyModel.isDummy = YES;
    [selectModels acc_addObject:dummyModel];
    self.grootDetailsModels  = [selectModels copy] ?: @[dummyModel];
    self.allowResearch = allowResearch;
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    
    @weakify(self);
    [self.grootDetailsModels enumerateObjectsUsingBlock:^(ACCGrootDetailsStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        if (!selectedModel) {
            self.p_currentIndex = 0;
            [self fixCellToCenter:NO];
            *stop = YES;
        } else if ([obj.speciesName isEqualToString:selectedModel.speciesName] || (obj.baikeId.longLongValue > 0 && [obj.baikeId isEqualToNumber:selectedModel.baikeId])) {
            self.p_currentIndex = idx;
            [self fixCellToCenter:NO];
            *stop = YES;
        }
    }];
    
    [self updateAllowResearchButton:self.allowResearch];
}

#pragma mark - private

- (void)fixCellToCenter:(BOOL)needFix {
    if (needFix) {
        BOOL didSlide = NO;
        float dragMiniDistance = ACC_SCREEN_WIDTH / 20.0f;
        if (self.p_dragStartX -  self.p_dragEndX >= dragMiniDistance) {
            self.p_currentIndex -= 1;
            didSlide = YES;
        }else if(self.p_dragEndX -  self.p_dragStartX >= dragMiniDistance){
            self.p_currentIndex += 1;
            didSlide = YES;
        }
        if ([self.delegate respondsToSelector:@selector(didSlideCard)] && didSlide) {
            // Used to track
            [self.delegate didSlideCard];
        }
    }
    NSInteger maxIndex = [self.collectionView numberOfItemsInSection:0] - 1;
    self.p_currentIndex = self.p_currentIndex <= 0 ? 0 : self.p_currentIndex;
    self.p_currentIndex = self.p_currentIndex >= maxIndex ? maxIndex : self.p_currentIndex;
   
    ACCGrootDetailsStickerModel *snapSelectedStickerModel =  [self.grootDetailsModels acc_objectAtIndex:self.p_currentIndex];;
    if (self.grootDetailsModels.count > 1) {
        self.selectTipLabel.text = @"识别到的物种是";
    } else {
        self.selectTipLabel.text = @"未识别出动植物，你还可以";
    }
    if ([self.delegate respondsToSelector:@selector(selectedGrootStickerModel:index:)]) {
        [self.delegate selectedGrootStickerModel:snapSelectedStickerModel index:self.p_currentIndex];
    }
    
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:self.p_currentIndex inSection:0];
    [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

- (void)didClickedSaveButton:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didClickedSaveButtonAction:)]) {
        [self.delegate didClickedSaveButtonAction:self.allowResearch];
    }
}

- (void)didClickCancelButton:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didClickCancelButtonAction)]) {
        [self.delegate didClickCancelButtonAction];
    }
}

- (void)didClickAllowResearchButton:(UIButton *)sender {
    self.allowResearch =  !self.allowResearch;
    [self updateAllowResearchButton:self.allowResearch];
    if ([self.delegate respondsToSelector:@selector(didClickAllowResearchButtonAction:)]) {
        [self.delegate didClickAllowResearchButtonAction:self.allowResearch];
    }
}

- (void)updateAllowResearchButton:(BOOL)allowed {
    if (allowed) {
        self.allowResearchButton.accessibilityLabel = @"勾选按钮，已勾选";
        [self.allowResearchButton setImage:ACCResourceImage(@"icon_filter_box_check") forState:UIControlStateNormal];
    } else {
        self.allowResearchButton.accessibilityLabel = @"勾选按钮，未勾选";
        [self.allowResearchButton setImage:ACCResourceImage(@"ic_checkbox_unselected") forState:UIControlStateNormal];
    }
}

#pragma mark - public

+ (CGSize)adaptionCollectionViewSize {
    CGFloat scaleWidth  = (284 * ACC_SCREEN_WIDTH) / 375;
    CGFloat scaleHeight = (214 * scaleWidth) / 284;
    return CGSizeMake(scaleWidth, scaleHeight);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.grootDetailsModels.count;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat edgeWidth = (ACC_SCREEN_WIDTH - [ACCGrootStickerSelectView adaptionCollectionViewSize].width)/2;
    UIEdgeInsets inset = UIEdgeInsetsMake(0, edgeWidth, 0, edgeWidth);
    return inset;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ACCGrootStickerSelectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ACCGrootStickerSelectCell.class) forIndexPath:indexPath];
    if (self.grootDetailsModels.count > indexPath.row) {
      ACCGrootDetailsStickerModel *model = [self.grootDetailsModels acc_objectAtIndex:indexPath.row];
        [cell configGrootStickerModel:model grootModels:self.grootDetailsModels];
    }
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat scaleWidth  = (284 * ACC_SCREEN_WIDTH) / 375;
    CGFloat scaleHeight = (214 * scaleWidth) / 284;
    return CGSizeMake(scaleWidth, scaleHeight);
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.p_dragStartX = scrollView.contentOffset.x;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.p_dragEndX = scrollView.contentOffset.x;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fixCellToCenter:YES];
    });
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.p_currentIndex = indexPath.row;
    [self fixCellToCenter:NO];
}

@end
