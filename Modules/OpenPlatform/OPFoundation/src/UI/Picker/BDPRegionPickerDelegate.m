//
//  BDPRegionPickerDelegate.m
//  TTMicroApp-Example
//
//  Created by 刘相鑫 on 2019/1/16.
//  Copyright © 2019 Bytedance.com. All rights reserved.
//

#import "BDPRegionPickerDelegate.h"
#import <OPFoundation/BDPRegionPickerPluginModel.h>
#import <OPFoundation/BDPPickerPluginModel.h>
#import <OPFoundation/BDPAddressPluginModel.h>
#import "BDPPickerView.h"
#import <OPFoundation/TMAAddressManager.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/UIColor+EMA.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

static NSString *const kRegionKey = @"r";           // region
static NSString *const kRegionCodeKey = @"c";       // code
static NSString *const kRegionEntitisKey = @"rE";   // regionEntitys

static const NSInteger kComponentCount = 3;
static const NSInteger kProvinceComponent = 0;
static const NSInteger kCityComponent = 1;
static const NSInteger kCountryComponent = 2;
static const CGFloat kPickerRowHeight = 48.f;

@interface BDPRegionPickerDelegate ()

@property (nonatomic, strong) BDPRegionPickerPluginModel *model;
@property (nonatomic, assign) NSInteger selectedProvinceIndex;
@property (nonatomic, assign) NSInteger selectedCityIndex;
@property (nonatomic, assign) NSInteger selectedCountryIndex;

@property (nonatomic, copy) NSArray *regionArray;
@property (nonatomic, copy) NSArray *currentCityArray;
@property (nonatomic, copy) NSArray *currentCountryArray;

@property (nonatomic, copy) NSDictionary *cityHeaderDic;
@property (nonatomic, copy) NSDictionary *countryHeaderDic;
@property (nonatomic, copy) NSDictionary *headerDic;

@end

@implementation BDPRegionPickerDelegate

#pragma mark - init

- (instancetype)initWithModel:(BDPRegionPickerPluginModel *)model pickerView:(UIPickerView *)pickerView
{
    self = [super init];
    if (self) {
        _model = model;
        _pickerView = pickerView;
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
        
        [self setupPickerData];
    }
    return self;
}

#pragma mark - model

- (void)setupPickerData
{
    [self setupCurrentComponent];
}

- (void)setupCurrentComponent
{
    NSString *currentProvince = [self currentItemForComponent:kProvinceComponent];
    if (!currentProvince) {
        _selectedProvinceIndex = 0;
        _selectedCityIndex = 0;
        _selectedCountryIndex = 0;
        return;
    }
    _selectedProvinceIndex = [self indexOfRegionName:currentProvince atRegionEntities:self.regionArray];
    
    NSString *currentCity = [self currentItemForComponent:kCityComponent];
    if (!currentCity) {
        _selectedCountryIndex = 0;
        _selectedCityIndex = 0;
        return;
    }
    
    NSArray *cityEntities = [self currentCityArray];
    _selectedCityIndex = [self indexOfRegionName:currentCity atRegionEntities:cityEntities];
    
    NSString *currentCountry = [self currentItemForComponent:kCountryComponent];
    if (!currentCountry) {
        _selectedCountryIndex = 0;
        return;
    }
    
    NSArray *countryEntities = [self currentCountryArray];
    _selectedCountryIndex = [self indexOfRegionName:currentCountry atRegionEntities:countryEntities];
    
}

- (NSString *)headerForComponent:(NSUInteger)component
{
    return self.model.customItem;
}

- (NSString *)currentItemForComponent:(NSUInteger)component
{
    NSString *current = nil;
    if (component < self.model.current.count) {
        return self.model.current[component];
    }
    
    return current;
}

#pragma mark - uI

- (void)selectCurrent
{
    [self.pickerView selectRow:self.selectedProvinceIndex inComponent:kProvinceComponent animated:NO];
    [self.pickerView selectRow:self.selectedCityIndex inComponent:kCityComponent animated:NO];
    [self.pickerView selectRow:self.selectedCountryIndex inComponent:kCountryComponent animated:NO];
}

#pragma mark - UIPickerViewDelegate

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return kPickerRowHeight;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *pickerLabel = (UILabel *) view;
    if (!pickerLabel) {
        pickerLabel = [[UILabel alloc] init];
        UIFont *font = [UIFont systemFontOfSize:17];
        if ([UIDevice currentDevice].systemVersion.doubleValue >= 9.0) {
            font = [UIFont systemFontOfSize:17];
        }
        [pickerLabel setTextColor:UDOCColor.textTitle];
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:font];
    }
    
    NSString *titleString = @"";
    if (component == kProvinceComponent) {
        NSDictionary *provinceEntity = self.regionArray[row];
        if ([provinceEntity isKindOfClass:NSDictionary.class]) {
            titleString = [provinceEntity bdp_stringValueForKey:kRegionKey];
        }
    } else if (component == kCityComponent) {
        NSArray *cityEntities = [self currentCityArray];
        NSDictionary *cityEntity = [cityEntities objectAtIndex:row];
        if ([cityEntity isKindOfClass:NSDictionary.class]) {
            titleString = [cityEntity bdp_stringValueForKey:kRegionKey];
        }
    } else if (component == kCountryComponent) {
        NSArray *countryEntites = [self currentCountryArray];
        NSDictionary *countryEntity = [countryEntites objectAtIndex:row];
        if ([countryEntity isKindOfClass:NSDictionary.class]) {
            titleString = [countryEntity bdp_stringValueForKey:kRegionKey];
        }
    }
    
    pickerLabel.text = titleString;
    
    return pickerLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component == kProvinceComponent) {
        self.selectedProvinceIndex = row;
        [pickerView reloadComponent:kCityComponent];
        [pickerView reloadComponent:kCountryComponent];
    } else if (component == kCityComponent) {
        self.selectedCityIndex = row;
        [pickerView reloadComponent:kCountryComponent];
    } else if (component == kCountryComponent) {
        self.selectedCountryIndex = row;
    }
    
    [self selectCurrent];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return kComponentCount;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == kProvinceComponent) {
        return self.regionArray.count;
    }
    
    if (component == kCityComponent) {
        NSArray *cities = [self cityEntitiesForProvinceIndex:self.selectedProvinceIndex withHeader:YES];
        return cities.count;
    }
    
    if (component == kCountryComponent) {
        NSArray *countryEntites = [self countryEntitiesForProvinceIndex:self.selectedProvinceIndex
                                                              cityIndex:self.selectedCityIndex
                                                             withHeader:YES];
        return countryEntites.count;
    }
    
    return 0;
}

#pragma mark - Data

- (NSArray *)cityEntitiesForProvinceIndex:(NSInteger)provinceIndex withHeader:(BOOL)insertHeader
{
    NSInteger index = provinceIndex;
    if (provinceIndex < 0 || provinceIndex >= self.regionArray.count) {
        index = 0;
    }
    
    NSDictionary *provinceEntity = self.regionArray[index];
    NSArray *cityEntities = [provinceEntity bdp_arrayValueForKey:kRegionEntitisKey];
    
    if (!insertHeader) {
        return cityEntities;
    }
    
    NSDictionary *header = [self cityHeaderDic];
    if (!header.count || cityEntities.firstObject == header) {
        return cityEntities;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:header];
    [array addObjectsFromArray:cityEntities];
    
    return array.copy;
}

- (NSArray *)countryEntitiesForProvinceIndex:(NSInteger)provinceIndex cityIndex:(NSInteger)cityIndex withHeader:(BOOL)insertHeader
{
    NSArray *cityEntities = [self cityEntitiesForProvinceIndex:provinceIndex withHeader:insertHeader];
    
    NSInteger index = cityIndex;
    if (cityIndex < 0 || cityIndex >= cityEntities.count) {
        index = 0;
    }
    
    NSDictionary *cityEntity = cityEntities[index];
    NSArray *countryEntites = [cityEntity bdp_arrayValueForKey:kRegionEntitisKey];
    if (!insertHeader) {
        return countryEntites;
    }
    
    NSDictionary *header = [self countryHeaderDic];
    if (!header.count || countryEntites.firstObject == header) {
        return countryEntites;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:header];
    [array addObjectsFromArray:countryEntites];
    
    return array.copy;
}

- (BDPAddressPluginModel *)currentAddress
{
    NSDictionary *provinceEntity = self.regionArray[self.selectedProvinceIndex];
    
    NSArray *cityEntities = [self currentCityArray];
    NSDictionary *cityEntity = cityEntities[self.selectedCityIndex];
    
    NSArray *countryEntities = [self currentCountryArray];
    NSDictionary *countryEntity = countryEntities[self.selectedCountryIndex];
    
    BDPAddressPluginModel *model = [BDPAddressPluginModel new];
    model.provinceName = [provinceEntity bdp_stringValueForKey:kRegionKey];
    model.cityName = [cityEntity bdp_stringValueForKey:kRegionKey];
    model.countyName = [countryEntity bdp_stringValueForKey:kRegionKey];

    return model;
}

- (NSInteger)indexOfRegionName:(NSString *)regionName atRegionEntities:(NSArray *)regionEntities
{
    if (!regionName) {
        return 0;
    }
    
    __block NSInteger index = NSNotFound;
    [regionEntities enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            if ([[obj bdp_stringValueForKey:kRegionKey] isEqualToString:regionName]) {
                index = idx;
                *stop = YES;
            }
        }
    }];
    
    if (index == NSNotFound) {
        index = 0;
    }
    
    return index;
}

#pragma mark - Getter && Setter

- (NSArray *)currentCityArray
{
    if (!_currentCityArray) {
        _currentCityArray = [self cityEntitiesForProvinceIndex:self.selectedProvinceIndex withHeader:YES];
    }
    
    return [_currentCityArray copy];
}

- (NSArray *)currentCountryArray
{
    if (!_currentCountryArray) {
        _currentCountryArray = [self countryEntitiesForProvinceIndex:self.selectedProvinceIndex
                                                           cityIndex:self.selectedCityIndex
                                                          withHeader:YES];
    }
    
    return [_currentCountryArray copy];
}

- (void)setSelectedProvinceIndex:(NSInteger)selectedProvinceIndex
{
    if (_selectedProvinceIndex != selectedProvinceIndex) {
        _selectedProvinceIndex = selectedProvinceIndex;
        _selectedCityIndex = 0;
        _selectedCountryIndex = 0;
        _currentCityArray = nil;
        _currentCountryArray = nil;
    }
}

- (void)setSelectedCityIndex:(NSInteger)selectedCityIndex
{
    if (_selectedCityIndex != selectedCityIndex) {
        _selectedCityIndex = selectedCityIndex;
        _selectedCountryIndex = 0;
        _currentCountryArray = nil;
    }
}

- (NSArray *)regionArray
{
    if (!_regionArray) {
        _regionArray = [[TMAAddressManager shareInstance] getAreaArray];
        NSDictionary *headerDic = [self headerDic];
        if (headerDic.count) {
            NSMutableArray *array = [NSMutableArray array];
            [array addObject:headerDic];
            [array addObjectsFromArray:_regionArray];
            _regionArray = array;
        }
    }
    
    return [_regionArray copy];
}

- (NSDictionary *)headerDic
{
    if (!_headerDic) {
        NSString *provinceHeader = [self headerForComponent:0];
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        if (provinceHeader) {
            [dic setValue:provinceHeader forKey:kRegionKey];
            [dic setValue:@(0) forKey:kRegionCodeKey];
            NSDictionary *cityHeader = [self cityHeaderDic];
            if (cityHeader.count) {
                [dic setValue:@[cityHeader] forKey:kRegionEntitisKey];
            }
            _headerDic = [dic copy];
        }
    }
    return _headerDic;
}

- (NSDictionary *)cityHeaderDic
{
    if (!_cityHeaderDic) {
        NSString *cityHeader = [self headerForComponent:1];
        if (cityHeader) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setValue:cityHeader forKey:kRegionKey];
            [dic setValue:@(0) forKey:kRegionCodeKey];
            NSDictionary *countryHeaderDic = [self countryHeaderDic];
            if (countryHeaderDic.count) {
                [dic setValue:@[[self countryHeaderDic]] forKey:kRegionEntitisKey];
            }
            _cityHeaderDic = [dic copy];
        }
    }
    
    return _cityHeaderDic;
}

- (NSDictionary *)countryHeaderDic
{
    if (!_countryHeaderDic) {
        NSString *countryHeader = [self headerForComponent:2];
        if (countryHeader) {
            _countryHeaderDic =  @{
                                   kRegionKey : countryHeader,
                                   kRegionCodeKey : @(0),
                                   };
        }
    }
    
    return _countryHeaderDic;
}



@end
