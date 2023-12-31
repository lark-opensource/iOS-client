//
//  AWERepoFilterModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//
#import "AWERepoFilterModel.h"
#import "AWERecordInformationRepoModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumData.h"

#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreativeKit/ACCMacrosTool.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import "AWEVideoFragmentInfo.h"

@interface AWEVideoPublishViewModel (AWERepoFilter) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoFilter)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoFilterModel.class];
	return info;
}

- (AWERepoFilterModel *)repoFilter
{
    AWERepoFilterModel *filterModel = [self extensionModelOfClass:AWERepoFilterModel.class];
    NSAssert(filterModel, @"extension model should not be nil");
    return filterModel;
}

@end


@interface AWERepoFilterModel()

@end

@implementation AWERepoFilterModel

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoFilterModel *model = [super copyWithZone:zone];
    model.capturedWithLightningFilter = self.capturedWithLightningFilter;
    model.editedWithLightningFilter = self.editedWithLightningFilter;
    model.hasDeselectionBeenMadeRecently = self.hasDeselectionBeenMadeRecently;
    return model;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - Public Method / Tracking

- (NSDictionary *)filterInfoDictionary
{
    AWERecordInformationRepoModel *recordInfoModel = [self.repository extensionModelOfClass:[AWERecordInformationRepoModel class]];
    
    NSMutableString *filterListMutableString = [NSMutableString stringWithString:@""];
    NSMutableString *filterIdListMutableString = [NSMutableString stringWithString:@""];
    ////////////////////////////////////////////////////////////////////////
    /// @description:  拍摄页图片滤镜信息
    ////////////////////////////////////////////////////////////////////////
    if(recordInfoModel.pictureToVideoInfo){
        if(!ACC_isEmptyString(recordInfoModel.pictureToVideoInfo.colorFilterId)){
            [filterListMutableString appendString: recordInfoModel.pictureToVideoInfo.colorFilterName];
            [filterIdListMutableString appendString: recordInfoModel.pictureToVideoInfo.colorFilterId];
        } else {
            if (recordInfoModel.pictureToVideoInfo.hasDeselectionBeenMadeRecently) {
                [filterIdListMutableString appendString: @"-1"];
            }
        }
    }else{
    ////////////////////////////////////////////////////////////////////////
    /// @description:  拍摄页分段视频滤镜信息
    ////////////////////////////////////////////////////////////////////////
        NSMutableArray *filters = @[].mutableCopy;
        NSMutableArray *filterIDs = @[].mutableCopy;
        
        for (AWEVideoFragmentInfo *fragment in recordInfoModel.fragmentInfo) {
            //
            if(![fragment isKindOfClass:[AWEVideoFragmentInfo class]]){
                continue;
            }
            
            NSString *name = fragment.colorFilterName;
            if (!name) {//老版本草稿没有存name，此处做兼容。后续可以与分析师协商去掉name的上报
                name = [AWEColorFilterDataManager effectWithID:fragment.colorFilterId].pinyinName;
                fragment.colorFilterName = name;
            }
            [filters acc_addObject:name];
            
            if (fragment.colorFilterId.length > 0) {
                [filterIDs acc_addObject:fragment.colorFilterId];
            } else if (fragment.hasDeselectionBeenMadeRecently) {
                [filterIDs acc_addObject:@"-1"];
            }
        }
        
        [filterListMutableString appendString: [filters componentsJoinedByString:@","]];
        [filterIdListMutableString appendString: [filterIDs componentsJoinedByString:@","]];
    }
    ////////////////////////////////////////////////////////////////////////
    // @description:  编辑页滤镜信息
    ////////////////////////////////////////////////////////////////////////
    
    NSString *colorFilterId = !ACC_isEmptyString(self.colorFilterId) ? self.colorFilterId : (self.hasDeselectionBeenMadeRecently ? @"-1" : @"");
    if (!ACC_isEmptyString(colorFilterId)) {
        if(!ACC_isEmptyString(filterIdListMutableString)){
            [filterIdListMutableString appendString:[NSString stringWithFormat:@",%@", colorFilterId]];
        }else{
            filterIdListMutableString = [NSMutableString stringWithString:colorFilterId];
        }
    }
    
    NSString *colorFilterName = [AWEColorFilterDataManager effectWithID:self.colorFilterId].pinyinName;
    if (!ACC_isEmptyString(colorFilterName)) {
        if(!ACC_isEmptyString(filterListMutableString)){
            [filterListMutableString appendString:[NSString stringWithFormat:@",%@",colorFilterName]];
        }else{
            filterListMutableString = [NSMutableString stringWithString:colorFilterName];
        }
    }
    
    ACCRepoImageAlbumInfoModel *albumInfo = [self.repository extensionModelOfClass:[ACCRepoImageAlbumInfoModel class]];
    if ([albumInfo isImageAlbumEdit]) {
        [albumInfo.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *filterId = obj.filterInfo.effectIdentifier;
            NSString *filterName = [AWEColorFilterDataManager effectWithID:filterId].pinyinName;
            if (filterId) {
                [filterIdListMutableString appendString:[NSString stringWithFormat:@"%@%@", filterIdListMutableString.length?@",":@"", filterId]];
            }
            if (filterName) {
                [filterListMutableString appendString:[NSString stringWithFormat:@"%@%@", filterListMutableString.length?@",":@"", filterName]];
            }
        }];
    }
    
    NSMutableDictionary *filterInfoMutableDictionary = @{}.mutableCopy;
    filterInfoMutableDictionary[@"filter_list"] = filterListMutableString;
    filterInfoMutableDictionary[@"filter_id_list"] = filterIdListMutableString;
    return [filterInfoMutableDictionary copy];
}

@end
