//
//  ACCMomentDebugMomentListViewController.m
//  Pods
//
//  Created by Pinka on 2020/6/17.
//

#if INHOUSE_TARGET

#import "ACCMomentDebugMomentListViewController.h"
#import "ACCMomentATIMManager.h"
#import "ACCMomentMediaDataProvider.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCMomentDebugLogConsoleViewController.h"

#import <Photos/Photos.h>

@interface ACCMomentDebugMomentListCell : UITableViewCell

@property (nonatomic, assign) PHImageRequestID requestId;

@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, strong) UILabel *mainTitleLabel;

@property (nonatomic, strong) PHAsset *asset;

@property (nonatomic, copy) dispatch_block_t tapImageAction;

@end

@implementation ACCMomentDebugMomentListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 140, 140)];
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.coverImageView.clipsToBounds = YES;
        self.coverImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAction:)];
        [self.coverImageView addGestureRecognizer:tapGr];
        
        [self.contentView addSubview:self.coverImageView];
        
        self.mainTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(160, 10, [UIScreen mainScreen].bounds.size.width - 160, 140)];
        self.mainTitleLabel.numberOfLines = 0;
        self.mainTitleLabel.minimumScaleFactor = 0.1;
        [self.contentView addSubview:self.mainTitleLabel];
    }
    
    return self;
}

- (void)setAsset:(PHAsset *)asset
{
    if (![_asset.localIdentifier isEqualToString:asset.localIdentifier]) {
        _asset = asset;
        
        if (self.requestId > 0) {
            [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
        }
        
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        option.networkAccessAllowed = NO;
        
        @weakify(self);
        self.requestId =
        [[PHImageManager defaultManager]
        requestImageForAsset:asset
        targetSize:CGSizeMake(200, 200)
        contentMode:PHImageContentModeAspectFill
        options:option
        resultHandler:^(UIImage *result, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                if (isDegraded) {
                    return;
                }
                
                if ([asset.localIdentifier isEqualToString:self.asset.localIdentifier]) {
                    self.coverImageView.image = result;
                }
            });
        }];
        
        if (PHAssetMediaTypeImage == asset.mediaType) {
            self.mainTitleLabel.textColor = [UIColor blackColor];
        } else {
            self.mainTitleLabel.textColor = [UIColor redColor];
        }
    }
}

- (void)onTapAction:(UITapGestureRecognizer *)gr
{
    if (self.tapImageAction) {
        self.tapImageAction();
    }
}

@end


@interface ACCMomentDebugMomentListViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) id input;

@property (nonatomic, copy  ) NSArray *sources;

@property (nonatomic, strong) NSMutableArray *allAsset;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ACCMomentDebugMomentListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
                                                  style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:ACCMomentDebugMomentListCell.class
           forCellReuseIdentifier:@"Cell"];
    self.tableView.rowHeight = 160.0;
    
    @weakify(self);
    if (self.vcType == ACCMomentDebugMomentListViewControllerType_MomentList) {
        self.title = @"Moment List";
        [[ACCMomentATIMManager shareInstance] setValue:@YES forKey:@"timIsReady"];
        [[ACCMomentATIMManager shareInstance]
         requestAIMResult:^(NSArray<ACCMomentAIMomentModel *> * _Nonnull result, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                self.sources = result;
                
                NSMutableArray *tmpAssetIds = [[NSMutableArray alloc] init];
                [result enumerateObjectsUsingBlock:^(ACCMomentAIMomentModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [tmpAssetIds addObject:obj.coverMaterialId];
                }];
                [self setAssetIds:tmpAssetIds];
                
                [self.tableView reloadData];
            });
        }];
    } else if (self.vcType == ACCMomentDebugMomentListViewControllerType_MomentMaterial) {
        self.title = @"Material List";
        ACCMomentAIMomentModel *moment = self.input;
        [[ACCMomentMediaDataProvider normalProvider]
         loadBIMWithUids:moment.uids resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable results, NSError * _Nullable error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 @strongify(self);
                 self.sources = results;
                 [self setAssetIds:moment.materialIds];
                 [self.tableView reloadData];
             });
        }];
    } else if (self.vcType == ACCMomentDebugMomentListViewControllerType_BIMList) {
        self.title = @"BIM List";
        [[ACCMomentMediaDataProvider normalProvider]
         loadBIMResultWithLimit:10000000 pageIndex:0 resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable result, BOOL endFlag, NSError * _Nullable error) {
            NSMutableArray *materialIds = [[NSMutableArray alloc] init];
            [result enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [materialIds addObject:obj.localIdentifier];
            }];
             dispatch_async(dispatch_get_main_queue(), ^{
                 @strongify(self);
                 self.title = [NSString stringWithFormat:@"BIM List (%lu)", (unsigned long)result.count];
                 self.sources = result;
                 [self setAssetIds:materialIds];
                 [self.tableView reloadData];
             });
        }];
    } else if (self.vcType == ACCMomentDebugMomentListViewControllerType_PeopleList) {
        self.title = @"People List";
        [[ACCMomentMediaDataProvider normalProvider]
         loadBIMResultWithLimit:10000000 pageIndex:0 resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable result, BOOL endFlag, NSError * _Nullable error) {
            NSMutableDictionary *peopleIdDict = [[NSMutableDictionary alloc] init];
            [result enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull oneBim, NSUInteger idx, BOOL * _Nonnull stop) {
                [oneBim.peopleIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSMutableArray *onePeopleArray = peopleIdDict[obj];
                    if (!onePeopleArray) {
                        onePeopleArray = [[NSMutableArray alloc] init];
                        peopleIdDict[obj] = onePeopleArray;
                    }
                    
                    [onePeopleArray addObject:oneBim];
                }];
            }];
            
            NSMutableArray *sources = [[NSMutableArray alloc] init];
            [peopleIdDict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray<ACCMomentBIMResult *> * _Nonnull obj, BOOL * _Nonnull stop) {
                [sources addObject:@[key, obj]];
            }];
            
            [sources sortUsingComparator:^NSComparisonResult(NSArray * _Nonnull obj1, NSArray * _Nonnull obj2) {
                NSNumber *key1 = obj1[0];
                NSNumber *key2 = obj2[0];
                
                NSArray *arr1 = obj1[1];
                NSArray *arr2 = obj2[1];
                
                if (arr1.count == arr2.count) {
                    if (key1.integerValue < key2.integerValue) {
                        return NSOrderedAscending;
                    } else {
                        return NSOrderedDescending;
                    }
                } else if (arr1.count > arr2.count) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }];
            
            NSMutableArray *materialIds = [[NSMutableArray alloc] init];
            [sources enumerateObjectsUsingBlock:^(NSArray * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray<ACCMomentBIMResult *> *bims = obj[1];
                [materialIds addObject:bims.firstObject.localIdentifier];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                self.sources = sources;
                [self setAssetIds:materialIds];
                [self.tableView reloadData];
            });
        }];
    } else if (self.vcType == ACCMomentDebugMomentListViewControllerType_TagList) {
        self.title = @"Tag List";
        [[ACCMomentMediaDataProvider normalProvider]
         loadBIMResultWithLimit:10000000 pageIndex:0 resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable result, BOOL endFlag, NSError * _Nullable error) {
            NSMutableDictionary *tagDict = [[NSMutableDictionary alloc] init];
            [result enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull oneBim, NSUInteger idx, BOOL * _Nonnull stop) {
                [oneBim.momentTags enumerateObjectsUsingBlock:^(VEAIMomentTag * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *key = [NSString stringWithFormat:@"name: %@\ntagId: %lld\ntagType: %ld", obj.name, obj.identity, (long)obj.type];
                    NSMutableArray *oneTagArray = tagDict[key];
                    
                    if (!oneTagArray) {
                        oneTagArray = [[NSMutableArray alloc] init];
                        tagDict[key] = oneTagArray;
                    }
                    
                    [oneTagArray addObject:oneBim];
                }];
            }];
            
            NSMutableArray *sources = [[NSMutableArray alloc] init];
            [tagDict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray<ACCMomentBIMResult *> * _Nonnull obj, BOOL * _Nonnull stop) {
                [sources addObject:@[key, obj]];
            }];
            
            [sources sortUsingComparator:^NSComparisonResult(NSArray * _Nonnull obj1, NSArray * _Nonnull obj2) {
                NSNumber *key1 = obj1[0];
                NSNumber *key2 = obj2[0];
                
                NSArray *arr1 = obj1[1];
                NSArray *arr2 = obj2[1];
                
                if (arr1.count == arr2.count) {
                    if (key1.integerValue < key2.integerValue) {
                        return NSOrderedAscending;
                    } else {
                        return NSOrderedDescending;
                    }
                } else if (arr1.count > arr2.count) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }];
            
            NSMutableArray *materialIds = [[NSMutableArray alloc] init];
            [sources enumerateObjectsUsingBlock:^(NSArray * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray<ACCMomentBIMResult *> *bims = obj[1];
                [materialIds addObject:bims.firstObject.localIdentifier];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                self.sources = sources;
                [self setAssetIds:materialIds];
                [self.tableView reloadData];
            });
        }];
    } else if (self.vcType == ACCMomentDebugMomentListViewControllerType_CommonBIMList) {
        self.title = @"List";
        NSMutableArray *materialIds = [[NSMutableArray alloc] init];
        NSArray<ACCMomentBIMResult *> *bims = self.input;
        [bims enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [materialIds addObject:obj.localIdentifier];
        }];
        
        self.sources = bims;
        [self setAssetIds:materialIds];
        [self.tableView reloadData];
    } else if (self.vcType == ACCMomentDebugMomentListViewControllerType_SimIdList) {
        self.title = @"SimId List";
        [[ACCMomentMediaDataProvider normalProvider]
         loadBIMResultWithLimit:10000000 pageIndex:0 resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable result, BOOL endFlag, NSError * _Nullable error) {
            NSMutableDictionary *simIdDict = [[NSMutableDictionary alloc] init];
            [result enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull oneBim, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMutableArray *oneSimIdArray = simIdDict[oneBim.simId];
                if (!oneSimIdArray) {
                    oneSimIdArray = [[NSMutableArray alloc] init];
                    simIdDict[oneBim.simId] = oneSimIdArray;
                }
                
                [oneSimIdArray addObject:oneBim];
            }];
            
            NSMutableArray *sources = [[NSMutableArray alloc] init];
            [simIdDict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray<ACCMomentBIMResult *> * _Nonnull obj, BOOL * _Nonnull stop) {
                [sources addObject:@[key, obj]];
            }];
            
            [sources sortUsingComparator:^NSComparisonResult(NSArray * _Nonnull obj1, NSArray * _Nonnull obj2) {
                NSNumber *key1 = obj1[0];
                NSNumber *key2 = obj2[0];
                
                NSArray *arr1 = obj1[1];
                NSArray *arr2 = obj2[1];
                
                if (arr1.count == arr2.count) {
                    if (key1.integerValue < key2.integerValue) {
                        return NSOrderedAscending;
                    } else {
                        return NSOrderedDescending;
                    }
                } else if (arr1.count > arr2.count) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }];
            
            NSMutableArray *materialIds = [[NSMutableArray alloc] init];
            [sources enumerateObjectsUsingBlock:^(NSArray * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray<ACCMomentBIMResult *> *bims = obj[1];
                [materialIds addObject:bims.firstObject.localIdentifier];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                self.sources = sources;
                [self setAssetIds:materialIds];
                [self.tableView reloadData];
            });
        }];
    }
}

- (BOOL)btd_prefersNavigationBarHidden
{
    return NO;
}

- (void)setAssetIds:(NSArray<NSString *> *)assetIds
{
    NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
    [[PHAsset fetchAssetsWithLocalIdentifiers:assetIds options:nil]
     enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        tmpDict[obj.localIdentifier] = obj;
    }];
    
    self.allAsset = [[NSMutableArray alloc] init];
    [assetIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PHAsset *oneAsset = tmpDict[obj];
        if (oneAsset) {
            [self.allAsset addObject:oneAsset];
        } else {
            [self.allAsset addObject:[NSNull null]];
        }
    }];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACCMomentDebugMomentListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    PHAsset *oneAsset = self.allAsset[indexPath.row];
    if ([oneAsset isKindOfClass:PHAsset.class]) {
        cell.asset = oneAsset;
    }
    
    @weakify(self);
    if (ACCMomentDebugMomentListViewControllerType_MomentList == self.vcType) {
        ACCMomentAIMomentModel *moment = self.sources[indexPath.row];
        cell.mainTitleLabel.text = [NSString stringWithFormat:@"%@\n素材id：%@",
                                    moment.title, [moment.uids.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
        cell.tapImageAction = ^{
            @strongify(self);
            [[ACCMomentATIMManager shareInstance]
             requestTIMResultWithAIMoment:moment
             usedPairs:nil
             completion:^(NSArray<ACCMomentTemplateModel *> * _Nonnull result, NSError * _Nonnull error) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     @strongify(self);
                     ACCMomentDebugLogConsoleViewController *vc = [[ACCMomentDebugLogConsoleViewController alloc] init];
                     NSMutableString *str = [[NSMutableString alloc] init];
                     [str appendString:moment.description];
                     [str appendString:@"\n---------------------------------------------\n以下是TIM的数据\n---------------------------------------------\n"];
                     [result enumerateObjectsUsingBlock:^(ACCMomentTemplateModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                         [str appendFormat:@"templateId: %@\n", @(obj.templateId)];
                         [str appendFormat:@"templateType: %@\n", @(obj.templateType)];
                         [obj.segInfos enumerateObjectsUsingBlock:^(ACCMomentMaterialSegInfo * _Nonnull seg, NSUInteger idx, BOOL * _Nonnull stop) {
                             [str appendFormat:@"segInfos[%lu]: %@\n", (unsigned long)idx, seg];
                         }];
                         [str appendString:@"\n\n"];
                     }];
                     vc.logText = str;
                    
                     [self.navigationController pushViewController:vc animated:YES];
                 });
            }];
        };
    } else if (ACCMomentDebugMomentListViewControllerType_MomentMaterial == self.vcType) {
        ACCMomentBIMResult *bim = self.sources[indexPath.row];
        cell.mainTitleLabel.text = [NSString stringWithFormat:@"peopleId: %@\ntags: %@",
                                    bim.peopleIds, bim.momentTags];
    } else if (ACCMomentDebugMomentListViewControllerType_BIMList == self.vcType ||
               ACCMomentDebugMomentListViewControllerType_CommonBIMList == self.vcType) {
        ACCMomentBIMResult *bim = self.sources[indexPath.row];
        cell.mainTitleLabel.text = [NSString stringWithFormat:@"peopleId: %@\ntags: %@",
                                    bim.peopleIds, bim.momentTags];
    } else if (ACCMomentDebugMomentListViewControllerType_PeopleList == self.vcType) {
        NSArray *people = self.sources[indexPath.row];
        cell.mainTitleLabel.text = [NSString stringWithFormat:@"peopleId: %@\ncount: %lu", people[0], (unsigned long)[people[1] count]];
    } else if (ACCMomentDebugMomentListViewControllerType_TagList == self.vcType) {
        NSArray *tag = self.sources[indexPath.row];
        cell.mainTitleLabel.text = [NSString stringWithFormat:@"%@\ncount: %lu", tag[0], (unsigned long)[tag[1] count]];
    } else if (ACCMomentDebugMomentListViewControllerType_SimIdList == self.vcType) {
        NSArray *simBims = self.sources[indexPath.row];
        cell.mainTitleLabel.text = [NSString stringWithFormat:@"simId: %@\ncount: %lu", simBims[0], (unsigned long)[simBims[1] count]];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sources.count;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (ACCMomentDebugMomentListViewControllerType_MomentList == self.vcType) {
        ACCMomentAIMomentModel *moment = self.sources[indexPath.row];
        ACCMomentDebugMomentListViewController *vc = [[ACCMomentDebugMomentListViewController alloc] init];
        vc.input = moment;
        vc.vcType = ACCMomentDebugMomentListViewControllerType_MomentMaterial;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (ACCMomentDebugMomentListViewControllerType_MomentMaterial == self.vcType ||
               ACCMomentDebugMomentListViewControllerType_BIMList == self.vcType ||
               ACCMomentDebugMomentListViewControllerType_CommonBIMList == self.vcType) {
        ACCMomentBIMResult *bim = self.sources[indexPath.row];
        ACCMomentDebugLogConsoleViewController *vc = [[ACCMomentDebugLogConsoleViewController alloc] init];
        vc.logText = [NSString stringWithFormat:
                      @"peopleId: %@\n"
                      "isLeader: %@\n"
                      "isPorn: %@\n"
                      "momentTags: %@\n"
                      "scoreInfos: %@\n"
                      "totalScoreInfo: %@\n"
                      "faceCount: %@\n"
                      "faceFeatures: %@\n"
                      "reFrameInfos: %@\n"
                      @"c3Feature: %@\n"
                      "simId: %@\n"
                      "时间: %@\n"
                      "地点: %@\n"
                      "duration: %@\n"
                      "localIdentifier: %@\n"
                      "uid: %@\n",
                      bim.peopleIds,
                      @(bim.isLeader),
                      @(bim.isPorn),
                      bim.momentTags,
                      bim.scoreInfos,
                      bim.scoreInfo,
                      @(bim.faceFeatures.count),
                      bim.faceFeatures,
                      bim.reframeInfos,
                      bim.c3Feature,
                      bim.simId,
                      bim.creationDate,
                      bim.locationName,
                      @(bim.duration),
                      bim.localIdentifier,
                      @(bim.uid)];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (ACCMomentDebugMomentListViewControllerType_PeopleList == self.vcType ||
               ACCMomentDebugMomentListViewControllerType_TagList == self.vcType ||
               ACCMomentDebugMomentListViewControllerType_SimIdList == self.vcType) {
        ACCMomentDebugMomentListViewController *vc = [[ACCMomentDebugMomentListViewController alloc] init];
        vc.input = self.sources[indexPath.row][1];
        vc.vcType = ACCMomentDebugMomentListViewControllerType_CommonBIMList;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end

#endif
