//
//  BDPTrackEventInfo.m
//  Timor
//
//  Created by 傅翔 on 2019/3/6.
//

#import "BDPTrackEventInfo.h"

#define KEY(sel) NSStringFromSelector(@selector(sel))

#define GETTER(name) -(NSString *)name {\
return _storage[KEY(name)];\
}

@interface BDPTrackEventInfo ()

@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSString *> *storage;

@end

@implementation BDPTrackEventInfo

@dynamic mp_id, mp_name, _param_for_special, mp_gid;

#pragma mark - Override
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    if (key) {
        self.storage[key] = obj;
    }
}

- (id)objectForKeyedSubscript:(id<NSCopying>)key {
    return key ? _storage[key] : nil;
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    BDPTrackEventInfo *info = [[BDPTrackEventInfo alloc] init];
    info.storage = [self.storage mutableCopy];
    info.uniqueID = self.uniqueID;
    return info;
}

#pragma mark - Computed Property
- (NSDictionary<NSString *,NSString *> *)infoDict {
    return [_storage copy];
}

#pragma mark - Accessor
- (void)setMp_id:(NSString *)mp_id {
    self.storage[KEY(mp_id)] = [mp_id copy];
}
GETTER(mp_id)

- (void)setMp_name:(NSString *)mp_name {
    self.storage[KEY(mp_name)] = [mp_name copy];
}
GETTER(mp_name)

- (void)setLaunch_from:(NSString *)launch_from {
    self.storage[KEY(launch_from)] = [launch_from copy];
}
GETTER(launch_from)

- (void)set_param_for_special:(NSString *)_param_for_special {
    self.storage[KEY(_param_for_special)] = [_param_for_special copy];
}
GETTER(_param_for_special)

- (void)setMp_gid:(NSString *)mp_gid {
    self.storage[KEY(mp_gid)] = [mp_gid copy];
}
GETTER(mp_gid)

- (void)setTrace_id:(NSString *)trace_id {
    self.storage[KEY(trace_id)] = [trace_id copy];
}
GETTER(trace_id)

#pragma mark - Lazy Loading
- (NSMutableDictionary<id<NSCopying>,NSString *> *)storage {
    if (!_storage) {
        _storage = [[NSMutableDictionary<id<NSCopying>,NSString *> alloc] init];
    }
    return _storage;
}
@end
