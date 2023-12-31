//
//  TestMmapUtility.m
//  RangersAppLog-Unit-Tests
//
//  Created by 朱元清 on 2021/1/10.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackMMap.h"
#import "BDAutoTrackUtility.h"

@interface TestMmapUtility : XCTestCase

@property (nonatomic) NSString *path;

@end

@implementation TestMmapUtility

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *trackerLibrary = bd_trackerLibraryPath();
    self.path = [NSString pathWithComponents:@[trackerLibrary, @"test_mmap.d"]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    if ([NSFileManager.defaultManager fileExistsAtPath:self.path]) {
        [NSFileManager.defaultManager removeItemAtPath:self.path error:nil];
    }
}

- (void)testMmapAndMunmap {
    // 初始状态不存在MMap文件
    XCTAssertFalse([NSFileManager.defaultManager fileExistsAtPath:self.path]);
    
    size_t kPagedRoundedSize = 4096;
    XCTAssertEqual(kPagedRoundedSize, round_page(kPagedRoundedSize));
    
    BDAutoTrackMMap *bdMMap = [[BDAutoTrackMMap alloc] initWithPath:self.path];
    // `mmapWithSize:`调用前未实际执行mmap
    XCTAssertFalse([bdMMap isMapped]);
    XCTAssertEqual(0, [bdMMap size]);
    
    void *mmapedArea = [bdMMap mmapWithSize:kPagedRoundedSize];
    // 测试创建MMap文件
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:self.path]);
    // 测试文件大小符合预期
    size_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil] fileSize];
    XCTAssertEqual(fileSize, kPagedRoundedSize);
    // 测试MMap成功拿到内存
    XCTAssertTrue(mmapedArea != NULL);
    // `mmapWithSize:`返回结果与Public方法`memory`返回结果应相同。
    XCTAssertEqual(mmapedArea, [bdMMap memory]);
    
    // MMap写入全0后，文件实际内容应为全0
    memset([bdMMap memory], 0, kPagedRoundedSize);
    NSData *zeroedData = [NSFileManager.defaultManager contentsAtPath:self.path];
    for (size_t i = 0; i < zeroedData.length; i++) {
        unsigned char byte = ((unsigned char *)[zeroedData bytes])[i];
        XCTAssertEqual(byte, 0);
    }
    
    // MMap写入全1后，文件实际内容应为全1
    memset([bdMMap memory], 0b11111111, kPagedRoundedSize);
    NSData *onedData = [NSFileManager.defaultManager contentsAtPath:self.path];
    for (size_t i = 0; i < onedData.length; i++) {
        unsigned char byte = ((unsigned char *)[onedData bytes])[i];
        XCTAssertEqual(byte, 0b11111111);
    }
    
    // Public方法`isMapped`应显示文件已成功mmap。
    XCTAssertTrue([bdMMap isMapped]);
    XCTAssertEqual(kPagedRoundedSize, [bdMMap size]);
    
    // test munmap success
    [bdMMap munmap];
    XCTAssertFalse([bdMMap isMapped]);
    XCTAssertEqual(0, [bdMMap size]);
}

@end
