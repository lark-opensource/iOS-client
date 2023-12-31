//
//  TTVideoEngine+MediaTrackInfo.m
//  TTVideoEngine
//
//  Created by zhangxin on 2022/5/12.
//

#import "TTVideoEngine+MediaTrackInfo.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngine+Private.h"
#import "NSDictionary+TTVideoEngine.h"

//mediatrackinfo model json field name
NSString *const kTTVideoEngineMediaTrackInfoModelIndexKey = @"index";
NSString *const kTTVideoEngineMediaTrackInfoModelTypeKey = @"type";
NSString *const kTTVideoEngineMediaTrackInfoModelLanguageKey = @"language";
NSString *const kTTVideoEngineMediaTrackInfoModelNameKey = @"name";
NSString *const kTTVideoEngineMediaTrackInfoModelGroupIdKey = @"group_id";

static
id checkNSNull(id obj) {
    return obj == [NSNull null] ? nil : obj;
}

@interface TTVideoEngineMediaTrackInfoModel()

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *groupId;

@end

@implementation TTVideoEngineMediaTrackInfoModel

- (instancetype)initWithDictionary:(NSDictionary * _Nonnull)dict {
    self = [super init];
    if (self) {
        NSNumber *index = checkNSNull(dict[kTTVideoEngineMediaTrackInfoModelIndexKey]);
        if (!index)
            return nil;
        self.index = [index integerValue];

        NSNumber *type = checkNSNull(dict[kTTVideoEngineMediaTrackInfoModelTypeKey]);
        if (!type)
            return nil;
        self.type = [type integerValue];
        
        self.language = checkNSNull(dict[kTTVideoEngineMediaTrackInfoModelLanguageKey]);
        self.name = checkNSNull(dict[kTTVideoEngineMediaTrackInfoModelNameKey]);
        self.groupId = checkNSNull(dict[kTTVideoEngineMediaTrackInfoModelGroupIdKey]);
    }
    return self;
}

- (NSDictionary *_Nullable)toDictionary {
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    [jsonDict setValue:@(self.index) forKey:kTTVideoEngineMediaTrackInfoModelIndexKey];
    [jsonDict setValue:@(self.type) forKey:kTTVideoEngineMediaTrackInfoModelTypeKey];
    [jsonDict setValue:self.language forKey:kTTVideoEngineMediaTrackInfoModelLanguageKey];
    [jsonDict setValue:self.name forKey:kTTVideoEngineMediaTrackInfoModelNameKey];
    [jsonDict setValue:self.groupId forKey:kTTVideoEngineMediaTrackInfoModelGroupIdKey];
    return jsonDict;
}

@end

@implementation TTVideoEngine (MediaTrackInfo)

- (NSArray<TTVideoEngineMediaTrackInfoModel *> *)getMediaTrackInfos {
    NSMutableArray<TTVideoEngineMediaTrackInfoModel *> *mediaTrackInfos = [NSMutableArray array];
    NSString *jsonStr = [self getStreamTrackInfo];
    if(!jsonStr) {
        return nil;
    }
    NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    NSEnumerator *enobj = [dataDict objectEnumerator];
    id key = [enobj nextObject];
    while (key) {
        id index = [key objectForKey: @"index"];
        id trackInfoStr = [key objectForKey: @"media_track_info"];
        NSDictionary *trackInfoJson = [NSJSONSerialization JSONObjectWithData:[trackInfoStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];

        NSMutableDictionary *temDict = [NSMutableDictionary dictionary];
        [temDict setValue:index forKey:@"index"];
        [temDict setValue:[trackInfoJson objectForKey: @"type"] forKey:@"type"];
        [temDict setValue:[trackInfoJson objectForKey: @"name"] forKey:@"name"];
        [temDict setValue:[trackInfoJson objectForKey: @"language"] forKey:@"language"];
        [temDict setValue:[trackInfoJson objectForKey: @"group_id"] forKey:@"group_id"];

        TTVideoEngineMediaTrackInfoModel *model = [[TTVideoEngineMediaTrackInfoModel alloc] initWithDictionary:temDict];
        [mediaTrackInfos addObject:model];
        key = [enobj nextObject];
    }
    return mediaTrackInfos;
}

@end
