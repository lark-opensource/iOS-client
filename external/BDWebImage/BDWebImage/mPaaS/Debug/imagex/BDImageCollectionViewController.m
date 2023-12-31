//
//  BDImageCollectionViewController.m
//  BDWebImage_Example
//
//  Created by 陈奕 on 2020/4/2.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import "BDImageCollectionViewController.h"
#import "BDImageDetailViewController.h"
#import "BDImageAdapter.h"
#import <BDWebImage.h>
#import <Masonry/Masonry.h>

@interface BDImageCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) BDImageView *imageView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation BDImageCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGRect r = CGRectMake(0, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        _imageView  = [[BDImageView alloc] initWithFrame:r];
        _imageView.layer.cornerRadius = 5;
        _imageView.layer.masksToBounds = YES;
        _imageView.backgroundColor = [UIColor grayColor];
        [self.contentView addSubview:_imageView];
        _label = [[UILabel alloc] init];
        _label.text = @"GIF";
        _label.font = [UIFont systemFontOfSize:10];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor whiteColor];
        _label.hidden = YES;
        [self.contentView addSubview:_label];
        [_label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).mas_offset(6);
            make.bottom.equalTo(self.contentView).mas_offset(-4);
        }];
    }
    return self;
}

@end

@interface BDImageCollectionViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableDictionary *animDict;
@property (nonatomic, strong) NSMutableDictionary *records;

@end

@implementation BDImageCollectionViewController

static NSString * const reuseIdentifier = @"BDImageCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.records = [NSMutableDictionary dictionary];
    self.animDict = [NSMutableDictionary dictionary];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat width = (self.view.bounds.size.width - 42) / 3;
    layout.itemSize = CGSizeMake(width, width);
    layout.minimumLineSpacing = 9;
    layout.minimumInteritemSpacing = 9;
    layout.sectionInset = UIEdgeInsetsMake(12, 12, 12, 12);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) collectionViewLayout:layout];
    [self.view addSubview:self.collectionView];
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerClass:[BDImageCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.center.equalTo(self.view);
    }];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageUrls.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BDImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    __block NSInteger index = indexPath.row;
    NSURL *url = [NSURL URLWithString:self.imageUrls[index]];
    NSString *type = [self.animDict objectForKey:@(index)];
    if (type != nil) {
        cell.label.text = type;
        cell.label.hidden = NO;
    }
    if ([BDImageAdapter sharedAdapter].isCyclePlayAnim){
        cell.imageView.infinityLoop = YES;
    }
    __weak BDImageCollectionViewCell *weakCell = cell;
//    __weak UICollectionView *weakCollectionView = collectionView;
    
    __weak typeof(self) weakSelf = self;
    [cell.imageView bd_setImageWithURL:url placeholder:nil options:[BDImageAdapter sharedAdapter].options completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        NSString *desc = @"";
#ifdef DEBUG
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary * _Nullable dictionary = request.recorder.imageMonitorV2Log;
            NSData * _Nullable data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
            NSString *_Nullable string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [[BDImageAdapter sharedAdapter] updateRecord:string];
        });
       desc = request.recorder.description;
#endif
        if (desc.length > 0) {
            [strongSelf.records setObject:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:request.recorder.imageMonitorV2Log options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding] forKey:@(index)];
        }
        if (((BDImage *)image).isAnimateImage) {
            NSString *type = @"GIF";
            switch (((BDImage *)image).codeType) {
                case BDImageCodeTypeWebP:
                    type = @"AWEBP";
                    break;
                case BDImageCodeTypeHeif:
                case BDImageCodeTypeHeic:
                    type = @"HEIF";
                    break;
                case BDImageCodeTypeAVIF:
                    type = @"AVIF";
                    break;
                default:
                    type = @"GIF";
                    break;
            }
            [strongSelf.animDict setObject:type forKey:@(index)];
//            NSInteger cellIndex = [weakCollectionView indexPathForCell:weakCell].row;
//            if ([request.currentRequestURL.absoluteString isEqualToString:strongSelf.imageUrls[cellIndex]]) {
                weakCell.label.text = type;
                weakCell.label.hidden = NO;
//            }
        } else {
            weakCell.label.text = @"";
            weakCell.label.hidden = NO;
        }
    }];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    BDImageDetailType type = [self.animDict.allKeys containsObject:@(indexPath.row)] ? BDImageDetailTypeAnim : BDImageDetailTypeStatic;
    
    BDImageDetailViewController *vc = [BDImageDetailViewController new];
    vc.navigationItem.title = @"图片详情";
    vc.url = self.imageUrls[indexPath.row];
    vc.record = [self.records objectForKey:@(indexPath.row)];
    vc.showType = type;
    [self.navigationController pushViewController:vc animated:YES];
    
}

@end
