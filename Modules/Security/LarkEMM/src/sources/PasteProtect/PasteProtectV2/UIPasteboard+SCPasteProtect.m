//
//  UIPasteboard+SCPasteProtect.m
//  LarkEMM
//
//  Created by ByteDance on 2023/12/22.
//

#import "UIPasteboard+SCPasteProtect.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "LarkEMM-Swift.h"
#import <LarkSecurityComplianceInfra/LarkSecurityComplianceInfra-Swift.h>
#import "SCPasteboardDefine.h"

@interface UIPasteboard ()

@end

@implementation UIPasteboard (SCPasteProtect)

+ (void)scReplacePasteboardMethod {
    [self logMessage:[NSString stringWithFormat:@"SCPasteProtect scReplacePasteboardMethod"]];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"_UIConcretePasteboard");
        [[self swizzleMap] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            SEL origin = NSSelectorFromString(key);
            SEL target = NSSelectorFromString(obj);
            BOOL result = [cls btd_swizzleInstanceMethod:origin with:target];
            [self logMessage:[NSString stringWithFormat:@"SCPasteProtect replace %@ with %@ result: %d", key, obj, result]];
        }];
    });
}

+ (NSDictionary *)swizzleMap {
    return @{
        // string
        NSStringFromSelector(@selector(string)): NSStringFromSelector(@selector(sc_string)),
        NSStringFromSelector(@selector(setString:)): NSStringFromSelector(@selector(sc_setString:)),
        
        // image
        NSStringFromSelector(@selector(image)): NSStringFromSelector(@selector(sc_image)),
        NSStringFromSelector(@selector(setImage:)): NSStringFromSelector(@selector(sc_setImage:)),
        
        //URL
        NSStringFromSelector(@selector(URL)): NSStringFromSelector(@selector(sc_URL)),
        NSStringFromSelector(@selector(setURL:)): NSStringFromSelector(@selector(sc_setURL:)),
        
        //Color
        NSStringFromSelector(@selector(color)): NSStringFromSelector(@selector(sc_color)),
        NSStringFromSelector(@selector(setColor:)): NSStringFromSelector(@selector(sc_setColor:)),
        
        // strings
        NSStringFromSelector(@selector(strings)): NSStringFromSelector(@selector(sc_strings)),
        NSStringFromSelector(@selector(setStrings:)): NSStringFromSelector(@selector(sc_setStrings:)),
        NSStringFromSelector(@selector(hasStrings)): NSStringFromSelector(@selector(sc_hasStrings)),
        
        //images
        NSStringFromSelector(@selector(images)): NSStringFromSelector(@selector(sc_images)),
        NSStringFromSelector(@selector(setImages:)): NSStringFromSelector(@selector(sc_setImages:)),
        NSStringFromSelector(@selector(hasImages)): NSStringFromSelector(@selector(sc_hasImages)),
        
        
        // URLs
        NSStringFromSelector(@selector(URLs)): NSStringFromSelector(@selector(sc_URLs)),
        NSStringFromSelector(@selector(setURLs:)): NSStringFromSelector(@selector(sc_setURLs:)),
        NSStringFromSelector(@selector(hasURLs)): NSStringFromSelector(@selector(sc_hasURLs)),
        
        // Colors
        NSStringFromSelector(@selector(colors)): NSStringFromSelector(@selector(sc_colors)),
        NSStringFromSelector(@selector(setColors:)): NSStringFromSelector(@selector(sc_setColors:)),
        NSStringFromSelector(@selector(hasColors)): NSStringFromSelector(@selector(sc_hasColors)),
        
        // item
        NSStringFromSelector(@selector(items)): NSStringFromSelector(@selector(sc_items)),
        NSStringFromSelector(@selector(setItems:options:)): NSStringFromSelector(@selector(sc_setItems:options:)),
        NSStringFromSelector(@selector(addItems:)): NSStringFromSelector(@selector(sc_addItems:)),
        
        //itemProvider
        NSStringFromSelector(@selector(itemProviders)): NSStringFromSelector(@selector(sc_itemProviders)),
        NSStringFromSelector(@selector(setItemProviders:)): NSStringFromSelector(@selector(sc_setItemProviders:)),
        NSStringFromSelector(@selector(setItemProviders:localOnly:expirationDate:)): NSStringFromSelector(@selector(sc_setItemProviders:localOnly:expirationDate:)),
        
        // itemSet
        NSStringFromSelector(@selector(itemSetWithPasteboardTypes:)): NSStringFromSelector(@selector(sc_itemSetWithPasteboardTypes:)),
        
        // values
        NSStringFromSelector(@selector(valuesForPasteboardType:inItemSet:)): NSStringFromSelector(@selector(sc_valuesForPasteboardType:inItemSet:)),
        
        // data
        NSStringFromSelector(@selector(dataForPasteboardType:)): NSStringFromSelector(@selector(sc_dataForPasteboardType:)),
        NSStringFromSelector(@selector(dataForPasteboardType:inItemSet:)): NSStringFromSelector(@selector(sc_dataForPasteboardType:inItemSet:)),
        NSStringFromSelector(@selector(setData:forPasteboardType:)): NSStringFromSelector(@selector(sc_setData:forPasteboardType:)),
        
        //PasteboardTypes
        NSStringFromSelector(@selector(pasteboardTypes)): NSStringFromSelector(@selector(sc_pasteboardTypes)),
        @"availableTypes": NSStringFromSelector(@selector(sc_availableTypes)),
        @"pasteboardTypesForItemSet:" :NSStringFromSelector(@selector(sc_pasteboardTypesForItemSet:)),
        NSStringFromSelector(@selector(containsPasteboardTypes:inItemSet:)): NSStringFromSelector(@selector(sc_containsPasteboardTypes:inItemSet:)),
        NSStringFromSelector(@selector(containsPasteboardTypes:)): NSStringFromSelector(@selector(sc_containsPasteboardTypes:)),
        
        //Items
        NSStringFromSelector(@selector(numberOfItems)): NSStringFromSelector(@selector(sc_numberOfItems)),
    };
}

#pragma  mark - String
- (NSString *)sc_string {
    NSString *string;
    if ([self shouldUseCustomPasteboardPaste]) {
        string = [[self pastePasteboard] sc_string];
    } else {
        string = [self sc_string];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeString];
    return string;
}

- (void)sc_setString:(NSString *)string {
    // 清理自定义剪贴板缓存在磁盘中的pointId等数据
    [self beforeSetContent: SCPasteboardDataTypeString];
    // 如果当前是系统剪贴板且当前的数据需要进入自定义剪贴板
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setString:string];
        [self updatePasteboardContent];
    } else {
        [self sc_setString:string];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeString];
}

- (BOOL)sc_hasStrings {
    return [[self customPasteboard] sc_hasStrings] || [UIPasteboard generalHasStrings];
}

- (NSArray<NSString *> *)sc_strings {
    NSArray<NSString *> *strings;
    if ([self shouldUseCustomPasteboardPaste]) {
        strings = [[self pastePasteboard] sc_strings];
    } else {
        strings = [self sc_strings];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeStrings];
    return strings;
}

- (void)sc_setStrings:(NSArray<NSString *> *)strings {
    [self beforeSetContent: SCPasteboardDataTypeString];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setStrings:strings];
        [self updatePasteboardContent];
    } else {
        [self sc_strings];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeString];
}

#pragma mark - Color
- (UIColor *)sc_color {
    UIColor *color;
    if ([self shouldUseCustomPasteboardPaste]) {
        color = [[self pastePasteboard] sc_color];
    } else {
        color = [self sc_color];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeColor];
    return color;
}

- (void)sc_setColor:(UIColor *)color {
    [self beforeSetContent: SCPasteboardDataTypeColor];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setColor:color];
        [self updatePasteboardContent];
    } else {
        [self sc_setColor:color];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeColor];
}

- (NSArray<UIColor *> *)sc_colors {
    NSArray<UIColor *> *colors;
    if ([self shouldUseCustomPasteboardPaste]) {
        colors = [[self pastePasteboard] sc_colors];
    } else {
        colors = [self sc_colors];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeColors];
    return colors;
}

- (void)sc_setColors:(NSArray<UIColor *> *)colors {
    [self beforeSetContent: SCPasteboardDataTypeColors];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setColors:colors];
        [self updatePasteboardContent];
    } else {
        [self sc_setColors:colors];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeColors];
}

- (BOOL)sc_hasColors {
    return [[self customPasteboard] sc_hasColors] || [[UIPasteboard generalPasteboard] sc_hasColors];
}

#pragma mark - Image
- (UIImage *)sc_image {
    UIImage *image;
    if ([self shouldUseCustomPasteboardPaste]) {
        image = [[self pastePasteboard] sc_image];
    } else {
        image = [self sc_image];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeImage];
    return image;
}

- (void)sc_setImage:(UIImage *)image {
    [self beforeSetContent: SCPasteboardDataTypeImage];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setImage:image];
        [self updatePasteboardContent];
    } else {
        [self sc_setImage:image];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeImage];
}

- (NSArray<UIImage *> *)sc_images {
    NSArray<UIImage *> *images;
    if ([self shouldUseCustomPasteboardPaste]) {
        images = [[self pastePasteboard] sc_images];
    } else {
        images = [self sc_images];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeImages];
    return images;
}

- (void)sc_setImages:(NSArray<UIImage *> *)images {
    [self beforeSetContent: SCPasteboardDataTypeImages];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setImages:images];
        [self updatePasteboardContent];
    } else {
        [self sc_setImages:images];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeImages];
}

- (BOOL)sc_hasImages {
    return [[self customPasteboard] sc_hasImages] || [[UIPasteboard generalPasteboard] sc_hasImages];
}

#pragma mark - URL
- (NSURL *)sc_URL {
    NSURL *url;
    if ([self shouldUseCustomPasteboardPaste]) {
        url = [[self pastePasteboard] sc_URL];
    } else {
        url = [self sc_URL];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeUrl];
    return url;
}

- (void)sc_setURL:(NSURL *)URL {
    [self beforeSetContent: SCPasteboardDataTypeUrl];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setURL:URL];
        [self updatePasteboardContent];
    } else {
        [self sc_setURL:URL];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeUrl];
}

- (NSArray<NSURL *> *)sc_URLs {
    NSArray<NSURL *> *urls;
    if ([self shouldUseCustomPasteboardPaste]) {
        urls = [[self pastePasteboard] sc_URLs];
    } else {
        urls = [self sc_URLs];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeUrls];
    return urls;
}

- (void)sc_setURLs:(NSArray<NSURL *> *)URLs {
    [self beforeSetContent: SCPasteboardDataTypeUrls];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setURLs:URLs];
        [self updatePasteboardContent];
    } else {
        [self sc_setURLs:URLs];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeUrls];
}

- (BOOL)sc_hasURLs {
    return [[self customPasteboard] sc_hasURLs] || [[UIPasteboard generalPasteboard] sc_hasURLs];
}

#pragma mark - Items
- (NSArray<NSDictionary<NSString *,id> *> *)sc_items {
    NSArray<NSDictionary<NSString *,id> *> *items;
    if ([self shouldUseCustomPasteboardPaste]) {
        items = [[self pastePasteboard] sc_items];
    } else {
        items = [self sc_items];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeItems];
    return items;
}

- (void)sc_addItems:(NSArray<NSDictionary<NSString *,id> *> *)items {
    [self beforeSetContent: SCPasteboardDataTypeItems];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_addItems:items];
    } else {
        [self sc_addItems:items];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeItems];
}

- (void)sc_setItems:(NSArray<NSDictionary<NSString *,id> *> *)items options:(NSDictionary<UIPasteboardOption,id> *)options {
    [self beforeSetContent: SCPasteboardDataTypeItems];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setItems:items options:options];
        [self updatePasteboardContent];
    } else {
        [self sc_setItems:items options:options];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeItems];
}

- (NSInteger)sc_numberOfItems {
    if ([self shouldUseCustomPasteboardPaste]) {
        return [[self pastePasteboard] sc_numberOfItems];
    } else {
        return [self sc_numberOfItems];
    }
}

#pragma mark - ItemProviders
- (NSArray<__kindof NSItemProvider *> *)sc_itemProviders {
    NSArray<__kindof NSItemProvider *> *itemProviders;
    if ([self shouldUseCustomPasteboardPaste]) {
        itemProviders = [[self pastePasteboard] sc_itemProviders];
    } else {
        itemProviders = [self sc_itemProviders];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeItemProviders];
    return itemProviders;
}
- (void)sc_setItemProviders:(NSArray<__kindof NSItemProvider *> *)itemProviders {
    [self beforeSetContent: SCPasteboardDataTypeItemProviders];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setItemProviders:itemProviders];
        [self updatePasteboardContent];
    } else {
        [self sc_setItemProviders:itemProviders];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeItemProviders];
}

- (void)sc_setItemProviders:(NSArray<NSItemProvider *> *)itemProviders localOnly:(BOOL)localOnly expirationDate:(NSDate *)expirationDate {
    if ([self shouldUseCustomPasteboardCopy]) {
        [self beforeSetContent: SCPasteboardDataTypeItemProviders];
        [[self copyPasteboard] sc_setItemProviders:itemProviders localOnly:localOnly expirationDate:expirationDate];
        [self updatePasteboardContent];
    } else {
        [self sc_setItemProviders:itemProviders localOnly:localOnly expirationDate:expirationDate];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeItemProviders];
}

#pragma mark - PasteboardTypes
- (NSArray<NSString *> *)sc_pasteboardTypes {
    if ([self shouldUseCustomPasteboardPaste]) {
        return [[self pastePasteboard] sc_pasteboardTypes];
    } else {
        return [self sc_pasteboardTypes];
    }
}

-(NSArray *)sc_availableTypes {
    if ([self shouldUseCustomPasteboardPaste]) {
        return [[self pastePasteboard] sc_availableTypes];
    } else {
        return [self sc_availableTypes];
    }
}

-(id)sc_pasteboardTypesForItemSet:(id)arg1 {
    if ([self shouldUseCustomPasteboardPaste]) {
        return [[self pastePasteboard] sc_pasteboardTypesForItemSet:arg1];
    } else {
        return [self sc_pasteboardTypesForItemSet:arg1];
    }
}

-(BOOL)sc_containsPasteboardTypes:(id)arg1 inItemSet:(id)arg2 {
    if ([self shouldUseCustomPasteboardPaste]) {
        return [[self pastePasteboard] sc_containsPasteboardTypes:arg1 inItemSet:arg2];
    } else {
        return [self sc_containsPasteboardTypes:arg1 inItemSet:arg2];
    }
}

-(BOOL)sc_containsPasteboardTypes:(id)arg1 {
    if ([self shouldUseCustomPasteboardPaste]) {
        return [[self pastePasteboard] sc_containsPasteboardTypes:arg1];
    } else {
        return [self sc_containsPasteboardTypes:arg1];
    }
}

#pragma mark - ItemSet
- (NSIndexSet *)sc_itemSetWithPasteboardTypes:(NSArray<NSString *> *)pasteboardTypes {
    if ([self shouldUseCustomPasteboardPaste]) {
        return [[self pastePasteboard] sc_itemSetWithPasteboardTypes:pasteboardTypes];
    } else {
        return [self sc_itemSetWithPasteboardTypes:pasteboardTypes];
    }
}

#pragma mark - Value
- (id)sc_valueForPasteboardType:(NSString *)pasteboardType {
    id value;
    if ([self shouldUseCustomPasteboardPaste]) {
        value = [[self pastePasteboard] sc_valueForPasteboardType:pasteboardType];
    } else {
        value = [self sc_valueForPasteboardType:pasteboardType];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeValue];
    return value;
}

- (void)sc_setValue:(id)value forPasteboardType:(NSString *)pasteboardType {
    [self beforeSetContent: SCPasteboardDataTypeValue];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setValue:value forPasteboardType:pasteboardType];
        [self updatePasteboardContent];
    } else {
        [self sc_setValue:value forPasteboardType:pasteboardType];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeValue];
}

- (NSArray *)sc_valuesForPasteboardType:(NSString *)pasteboardType inItemSet:(NSIndexSet *)itemSet {
    NSArray *values;
    if ([self shouldUseCustomPasteboardPaste]) {
        values = [[self pastePasteboard] sc_valuesForPasteboardType:pasteboardType inItemSet:itemSet];
    } else {
        values = [self sc_valuesForPasteboardType:pasteboardType inItemSet:itemSet];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeValues];
    return values;
}

#pragma mark - Data
- (NSData *)sc_dataForPasteboardType:(NSString *)pasteboardType {
    NSData *data;
    if ([self shouldUseCustomPasteboardPaste]) {
        data = [[self pastePasteboard] sc_dataForPasteboardType:pasteboardType];
    } else {
        data = [self sc_dataForPasteboardType:pasteboardType];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeData];
    return data;
}

- (NSArray<NSData *> *)sc_dataForPasteboardType:(NSString *)pasteboardType inItemSet:(NSIndexSet *)itemSet {
    NSArray<NSData *> *data;
    if ([self shouldUseCustomPasteboardPaste]) {
        data = [[self pastePasteboard] sc_dataForPasteboardType:pasteboardType inItemSet:itemSet];
    } else {
        data = [self sc_dataForPasteboardType:pasteboardType inItemSet:itemSet];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeData];
    return data;
}

- (void)sc_setData:(NSData *)data forPasteboardType:(NSString *)pasteboardType {
    [self beforeSetContent: SCPasteboardDataTypeData];
    if ([self shouldUseCustomPasteboardCopy]) {
        [[self copyPasteboard] sc_setData:data forPasteboardType:pasteboardType];
        [self updatePasteboardContent];
    } else {
        [self sc_setData:data forPasteboardType:pasteboardType];
    }
    [self afterAcessPasteboard: SCPasteboardDataTypeData];
}

- (BOOL)shouldUseCustomPasteboardCopy {
    if ([self isEqual:[UIPasteboard generalPasteboard]] && [self copyPasteboard]) {
        return true;
    }
    return false;
}

-(void)beforeSetContent:(SCPasteboardDataType)type {
    [UIPasteboard logMessage:[NSString stringWithFormat:@"SCPasteboard: pasteboard %@ beforeSetContent with dataType %@ ", self.name, @(type)]];
    [SCPasteboardWrapper clearLastPointId];
}

-(void)afterAcessPasteboard:(SCPasteboardDataType)type {
    [UIPasteboard logMessage:[NSString stringWithFormat:@"SCPasteboard: pasteboard %@ afterAcessPasteboard with dataType %@", self.name, @(type)]];
    [SCPasteboardWrapper clearSCPasteboardConfig];
}

- (void)clearGeneralPasteboard {
    if ([self isEqual:[UIPasteboard generalPasteboard]] && [UIPasteboard generalHasNewValue]) {
        [[UIPasteboard generalPasteboard] sc_setItems:@[] options:nil];
    }
}

- (void)updatePasteboardContent {
    [SCPasteboardWrapper updateCustomPasteboard];
    [self clearGeneralPasteboard];
}

- (UIPasteboard *)customPasteboard {
    return [SCPasteboardWrapper customPasteboard];
}

- (UIPasteboard *)copyPasteboard {
    return [SCPasteboardWrapper copyPasteboard];
}

- (BOOL)shouldUseCustomPasteboardPaste{
    if ([self isEqual:[UIPasteboard generalPasteboard]] && [self pastePasteboard]) {
        return true;
    }
    return false;
}

- (UIPasteboard *)pastePasteboard {
    if ([UIPasteboard generalHasNewValue]) {
        return nil;
    }
    return [SCPasteboardWrapper pastePasteboard];
}

+ (void)logMessage:(NSString *)message {
    [SCLoggerWrapper sc_info:message file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent]];
}

+ (BOOL)generalHasNewValue {
    return [[UIPasteboard generalPasteboard] sc_hasStrings] || [[UIPasteboard generalPasteboard] sc_hasColors] || [[UIPasteboard generalPasteboard] sc_hasImages] || [[UIPasteboard generalPasteboard] sc_hasURLs];
}

+ (BOOL)generalHasStrings {
    return [[UIPasteboard generalPasteboard] sc_hasStrings];
}

+ (BOOL)generalHasColors {
    return [[UIPasteboard generalPasteboard] sc_hasColors];
}

+ (BOOL)generalHasImages {
    return [[UIPasteboard generalPasteboard] sc_hasImages];
}

+ (BOOL)generalHasUrls {
    return [[UIPasteboard generalPasteboard] sc_hasURLs];
}

@end
