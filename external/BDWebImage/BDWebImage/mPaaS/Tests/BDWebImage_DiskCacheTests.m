//
//  BDWebImage_DiskCacheTests.m
//  BDWebImage_Tests
//
//  Created by 陈奕 on 2019/10/12.
//  Copyright © 2019 Bytedance.com. All rights reserved.
//

//#import <XCTest/XCTest.h>
//#import <BDDiskYYCache.h>
//#import <BDImageDiskFileCache.h>
//#import <BDImageCache.h>
//
//static NSString *const kBDDiskCacheTestName = @"com.bd.test.disk.cache";
//
//@interface BDWebImage_DiskCacheTests : XCTestCase
//
//@property (nonatomic, strong) BDDiskYYCache *yy;
//@property (nonatomic, strong) BDImageDiskFileCache *bd;
//
//@end
//
//@implementation BDWebImage_DiskCacheTests
//
//- (void)setUp {
//    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
//    NSLog(@"%@", cachePath);
//    _yy = [[BDDiskYYCache alloc] initWithCachePath:[cachePath stringByAppendingPathComponent:kBDDiskCacheTestName]];
//    _bd = [[BDImageDiskFileCache alloc] initWithCachePath:[cachePath stringByAppendingPathComponent:kBDDiskCacheTestName]];
//}
//
//- (void)tearDown {
//    [_yy removeAllData];
//    [_bd removeAllData];
//}
//
//- (void)test_1_YYWriteDataPerformance {
//    int loops = 100;
//    NSMutableArray *arrDatas = [NSMutableArray arrayWithCapacity:loops];
//    NSMutableArray *arrDataKeys = [NSMutableArray arrayWithCapacity:loops];
//    for (size_t index = 0; index < loops; index++) {
//        NSString *str = [NSString stringWithFormat:@"%s-%d", __FILE__, rand()];
//        [arrDatas addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
//
//        NSString *dataKey = [NSString stringWithFormat:@"str-%zu", index];
//        [arrDataKeys addObject:dataKey];
//    }
//
//    [self measureBlock:^{
//        for (int index = 0; index < loops; index++) {
//            NSData *data = arrDatas[index];
//            NSString *dataKey = arrDataKeys[index];
//            [self->_yy setData:data forKey:dataKey];
//        }
//    }];
//}
//
//- (void)test_2_FileWriteDataPerformance {
//    int loops = 100;
//    NSMutableArray *arrDatas = [NSMutableArray arrayWithCapacity:loops];
//    NSMutableArray *arrDataKeys = [NSMutableArray arrayWithCapacity:loops];
//    for (size_t index = 0; index < loops; index++) {
//        NSString *str = [NSString stringWithFormat:@"%s-%d", __FILE__, rand()];
//        [arrDatas addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
//
//        NSString *dataKey = [NSString stringWithFormat:@"str-%zu", index];
//        [arrDataKeys addObject:dataKey];
//    }
//
//    [self measureBlock:^{
//        for (int index = 0; index < loops; index++) {
//            NSData *data = arrDatas[index];
//            NSString *dataKey = arrDataKeys[index];
//            [self->_bd setData:data forKey:dataKey];
//        }
//    }];
//}
//
//- (void)test_3_YYReadDataPerformance {
//    int loops = 100;
//    NSMutableArray *arrDatas = [NSMutableArray arrayWithCapacity:loops];
//    NSMutableArray *arrDataKeys = [NSMutableArray arrayWithCapacity:loops];
//    for (size_t index = 0; index < loops; index++) {
//        NSString *str = [NSString stringWithFormat:@"%s-%d", __FILE__, rand()];
//        [arrDatas addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
//
//        NSString *dataKey = [NSString stringWithFormat:@"str-%zu", index];
//        [arrDataKeys addObject:dataKey];
//    }
//
//    for (int index = 0; index < loops; index++) {
//        NSData *data = arrDatas[index];
//        NSString *dataKey = arrDataKeys[index];
//        [self->_yy setData:data forKey:dataKey];
//    }
//
//    [self measureBlock:^{
//        for (int index = 0; index < loops; index++) {
//            NSString *dataKey = arrDataKeys[index];
//            [self->_yy dataForKey:dataKey];
//        }
//    }];
//}
//
//- (void)test_4_FileReadDataPerformance {
//    int loops = 100;
//    NSMutableArray *arrDatas = [NSMutableArray arrayWithCapacity:loops];
//    NSMutableArray *arrDataKeys = [NSMutableArray arrayWithCapacity:loops];
//    for (size_t index = 0; index < loops; index++) {
//        NSString *str = [NSString stringWithFormat:@"%s-%d", __FILE__, rand()];
//        [arrDatas addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
//
//        NSString *dataKey = [NSString stringWithFormat:@"str-%zu", index];
//        [arrDataKeys addObject:dataKey];
//    }
//
//    for (int index = 0; index < loops; index++) {
//        NSData *data = arrDatas[index];
//        NSString *dataKey = arrDataKeys[index];
//        [self->_bd setData:data forKey:dataKey];
//    }
//
//    [self measureBlock:^{
//        for (int index = 0; index < loops; index++) {
//            NSString *dataKey = arrDataKeys[index];
//            [self->_bd dataForKey:dataKey];
//        }
//    }];
//}
//
//- (void)test_5_YYRemoveDataPerformance {
//    int loops = 100;
//    NSMutableArray *arrDatas = [NSMutableArray arrayWithCapacity:loops];
//    NSMutableArray *arrDataKeys = [NSMutableArray arrayWithCapacity:loops];
//    for (size_t index = 0; index < loops; index++) {
//        NSString *str = [NSString stringWithFormat:@"%s-%d", __FILE__, rand()];
//        [arrDatas addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
//
//        NSString *dataKey = [NSString stringWithFormat:@"str-%zu", index];
//        [arrDataKeys addObject:dataKey];
//    }
//
//    for (int index = 0; index < loops; index++) {
//        NSData *data = arrDatas[index];
//        NSString *dataKey = arrDataKeys[index];
//        [self->_yy setData:data forKey:dataKey];
//    }
//
//    [self measureBlock:^{
//        for (int index = 0; index < loops; index++) {
//            NSString *dataKey = arrDataKeys[index];
//            [self->_yy removeDataForKey:dataKey];
//        }
//    }];
//}
//
//- (void)test_6_FileRemoveDataPerformance {
//    int loops = 100;
//    NSMutableArray *arrDatas = [NSMutableArray arrayWithCapacity:loops];
//    NSMutableArray *arrDataKeys = [NSMutableArray arrayWithCapacity:loops];
//    for (size_t index = 0; index < loops; index++) {
//        NSString *str = [NSString stringWithFormat:@"%s-%d", __FILE__, rand()];
//        [arrDatas addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
//
//        NSString *dataKey = [NSString stringWithFormat:@"str-%zu", index];
//        [arrDataKeys addObject:dataKey];
//    }
//
//    for (int index = 0; index < loops; index++) {
//        NSData *data = arrDatas[index];
//        NSString *dataKey = arrDataKeys[index];
//        [self->_bd setData:data forKey:dataKey];
//    }
//
//    [self measureBlock:^{
//        for (int index = 0; index < loops; index++) {
//            NSString *dataKey = arrDataKeys[index];
//            [self->_bd removeDataForKey:dataKey];
//        }
//    }];
//}
//
//- (void)test_7_YYRemoveDataPerformance {
//    int loops = 100;
//    NSMutableArray *arrDatas = [NSMutableArray arrayWithCapacity:loops];
//    NSMutableArray *arrDataKeys = [NSMutableArray arrayWithCapacity:loops];
//    for (size_t index = 0; index < loops; index++) {
//        NSString *str = [NSString stringWithFormat:@"%s-%d", __FILE__, rand()];
//        [arrDatas addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
//
//        NSString *dataKey = [NSString stringWithFormat:@"str-%zu", index];
//        [arrDataKeys addObject:dataKey];
//    }
//
//    for (int index = 0; index < loops; index++) {
//        NSData *data = arrDatas[index];
//        NSString *dataKey = arrDataKeys[index];
//        if (index == 500) {
//            sleep(1);
//        }
//        [self->_yy setData:data forKey:dataKey];
//    }
//    sleep(2);
//
//    BDImageCacheConfig *config = [BDImageCacheConfig new];
//    config.diskAgeLimit = 3;
//    config.diskSizeLimit = [_yy totalSize] / 4;
//    [_yy setConfig:config];
//
//    [self measureBlock:^{
//        [self->_yy removeExpiredData];
//    }];
//}
//
//- (void)test_8_FileRemoveDataPerformance {
//    int loops = 1000;
//    NSMutableArray *arrDatas = [NSMutableArray arrayWithCapacity:loops];
//    NSMutableArray *arrDataKeys = [NSMutableArray arrayWithCapacity:loops];
//    for (size_t index = 0; index < loops; index++) {
//        NSString *str = [NSString stringWithFormat:@"%s-%d", __FILE__, rand()];
//        [arrDatas addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
//
//        NSString *dataKey = [NSString stringWithFormat:@"str-%zu", index];
//        [arrDataKeys addObject:dataKey];
//    }
//
//    for (int index = 0; index < loops; index++) {
//        NSData *data = arrDatas[index];
//        NSString *dataKey = arrDataKeys[index];
//        if (index == 500) {
//            sleep(1);
//        }
//        [self->_bd setData:data forKey:dataKey];
//    }
//    sleep(2);
//
//    BDImageCacheConfig *config = [BDImageCacheConfig new];
//    config.diskAgeLimit = 3;
//    config.diskSizeLimit = [_bd totalSize] / 4;
//    [_bd setConfig:config];
//
//    [self measureBlock:^{
//        [self->_bd removeExpiredData];
//    }];
//}
//
//@end
