//
//  ACCRecordFlowServiceTests.m
//  CameraClient-Pods-AwemeTests-Unit-_Tests
//
//  Created by liyingpeng on 2020/12/7.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <CameraClient/ACCRecordFlowServiceImpl.h>
#import <CameraClient/ACCRecorderWrapper.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

@interface ACCRecordFlowServiceTests : XCTestCase

@property (nonatomic, strong) id mockFlow;
@property (nonatomic, strong) id mockRecorder;

@end

@implementation ACCRecordFlowServiceTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    ACCRecordFlowServiceImpl *flowService = [[ACCRecordFlowServiceImpl alloc] init];
    id mockCameraService = OCMProtocolMock(@protocol(ACCCameraService));
    id mockRecorder = OCMProtocolMock(@protocol(ACCRecorderProtocol));

    ACCRecordFlowServiceImpl * mockFlow = OCMPartialMock(flowService);
    OCMStub([mockFlow cameraService]).andReturn(mockCameraService);
    OCMStub([mockCameraService recorder]).andReturn(mockRecorder);

    self.mockFlow = mockFlow;
    self.mockRecorder = mockRecorder;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [(id)self.mockFlow stopMocking];
    [(id)self.mockRecorder stopMocking];
    self.mockFlow = nil;
    self.mockRecorder = nil;
}

- (void)testFlowServiceTackPicktureWithRecording {
    OCMStub([self.mockRecorder isRecording]).andReturn(YES);
    OCMStub([self.mockRecorder cameraMode]).andReturn(HTSCameraModePhoto);
    OCMReject([self.mockRecorder captureStillImageWithCompletion:OCMOCK_ANY]);
    [self.mockFlow takePicture];
}

- (void)testFlowServiceTackPicktureWithVideoMode {
    OCMStub([self.mockRecorder isRecording]).andReturn(NO);
    OCMStub([self.mockRecorder cameraMode]).andReturn(HTSCameraModeVideo);
    OCMReject([self.mockRecorder captureStillImageWithCompletion:OCMOCK_ANY]);
    [self.mockFlow takePicture];
}

- (void)testFlowServiceTackPickture {
    OCMStub([self.mockRecorder isRecording]).andReturn(NO);
    OCMStub([self.mockRecorder cameraMode]).andReturn(HTSCameraModePhoto);
    OCMExpect([self.mockRecorder captureStillImageWithCompletion:OCMOCK_ANY]);
    [self.mockFlow takePicture];
    OCMVerifyAll(self.mockRecorder);
}

@end
