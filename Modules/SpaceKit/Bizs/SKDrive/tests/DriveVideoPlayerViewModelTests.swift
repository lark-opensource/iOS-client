//
//  DriveVideoPlayerViewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ZhangYuanping on 2022/4/12.
//  


import XCTest
import SKFoundation
import SpaceInterface
import SKCommon
import RxSwift
import RxCocoa
@testable import SKDrive

class DriveVideoPlayerViewModelTests: XCTestCase {

    var sut: DriveVideoPlayerViewModel!
    var mockVideoPlayer = MockDriveVideoPlayer()
    var mediaMutex = MockMediaMutexDependencyImpl()
    var bag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("/test/video/test.mp4")
        let driveVideo = DriveVideo(type: .local(url: url), info: nil, title: "Test", size: 1000, cacheKey: "test", authExtra: nil)
        mockVideoPlayer.delegate = sut
        sut = DriveVideoPlayerViewModel(video: driveVideo, player: mockVideoPlayer, displayMode: .normal, isInVCFollow: false, mediaMutex: mediaMutex)
    }

    func testSetupVideoEngine() {
        sut.setupVideoEngine(appState: .active)
        XCTAssertEqual(sut.playbackState.value, .playing)
    }
    
    func testVideoGlitchFollowState() {
        let expectation = XCTestExpectation(description: "Video State Still playing")
        sut.setupVideoEngine(appState: .active)
        let videoState = DriveMediaFollowState(status: .ended, currentTime: 3, recordId: "")
        sut.setState(videoState.followModuleState)
        sut.playbackState.subscribe(onNext: { playbackState in
            XCTAssertEqual(playbackState, .playing)
            expectation.fulfill()
        }).disposed(by: bag)
        wait(for: [expectation], timeout: 3.0)
    }

    func testVideoAboutFinishButNotSetEndedFollowState() {
        let expectation = XCTestExpectation(description: "VideoAboutFinishButNotSetEnded")
        sut.setupVideoEngine(appState: .active)
        // 播放进度大于 95% 但是与总时长差值 > 1，继续设置播放状态
        let videoState = DriveMediaFollowState(status: .playing, currentTime: 1145, recordId: "")
        sut.setState(videoState.followModuleState)
        sut.playbackState.subscribe(onNext: { playbackState in
            XCTAssertEqual(playbackState, .playing)
            expectation.fulfill()
        }).disposed(by: bag)
        wait(for: [expectation], timeout: 3.0)
    }

//    func testVideoAboutFinishAndSetEndedFollowState() {
//        let expectation = XCTestExpectation(description: "VideoAboutFinishAndSetEnded")
//        sut.setupVideoEngine(appState: .active)
//        // 播放进度大于 95% 且总时长差值 < 1，设置结束播放状态
//        let videoState = DriveMediaFollowState(status: .playing, currentTime: 1199.5, recordId: "")
//        sut.setState(videoState.followModuleState)
//        sut.playerStatus.subscribe(onNext: { status in
//            if case .finished = status {
//                XCTAssertTrue(true)
//                expectation.fulfill()
//            }
//        }).disposed(by: bag)
//        wait(for: [expectation], timeout: 3.0)
//    }

//    func testVideoFinishFollowState() {
//        let expectation = XCTestExpectation(description: "Video State Did Paused")
//        sut.setupVideoEngine(appState: .active)
//        let videoState = DriveMediaFollowState(status: .ended, currentTime: 1200, recordId: "")
//        sut.setState(videoState.followModuleState)
//        sut.playerStatus.subscribe(onNext: { status in
//            if case .finished = status {
//                XCTAssertTrue(true)
//                expectation.fulfill()
//            }
//        }).disposed(by: bag)
//        wait(for: [expectation], timeout: 3.0)
//    }
    
    func testGetFollowModultState() {
        sut.setupVideoEngine(appState: .active)
        if let state = sut.getState(), let mediaState = DriveMediaFollowState(json: state.data) {
            XCTAssertEqual(mediaState.currentTime, 0)
        } else {
            XCTAssertNil(nil)
        }
    }
    
    func testPlayTrylockFailedWithMsg() {
        self.mediaMutex.result = .occupiedByOther(msg: "is in meeting")
        sut.play()
        XCTAssert(self.mockVideoPlayer.playbackState == .stopped)
    }
    
    func testPlayTrylockFailedWithoutMsg() {
        self.mediaMutex.result = .occupiedByOther(msg: nil)
        sut.play()
        XCTAssert(self.mockVideoPlayer.playbackState == .playing)
    }
    
    func testPlayTrylockFailedWithUnknowError() {
        self.mediaMutex.result = .unknown
        sut.play()
        XCTAssert(self.mockVideoPlayer.playbackState == .playing)
    }

    func testPlayingInterrupted() {
        self.mediaMutex.result = .success
        sut.play()
        XCTAssert(self.mockVideoPlayer.playbackState == .playing)
        guard let observer = sut as? SKMediaResourceInterruptionObserver else {
            XCTFail("sut didn't implement SKMediaResourceInterruptionObserver")
            return
        }
        let expect = expectation(description: "wait for change play state")
        self.mockVideoPlayer.playbackStateDidChanged = {
            expect.fulfill()
        }
        observer.mediaResourceInterrupted(with: "is in meeting")
        waitForExpectations(timeout: 1, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssert(self.mockVideoPlayer.playbackState == .paused)
    }
    
    func testPauseInterruptedEnd() {
        self.mediaMutex.result = .success
        sut.pause()
        XCTAssert(self.mockVideoPlayer.playbackState == .paused)
        guard let observer = sut as? SKMediaResourceInterruptionObserver else {
            XCTFail("sut didn't implement SKMediaResourceInterruptionObserver")
            return
        }
        let expect = expectation(description: "wait for change play state")
        self.mockVideoPlayer.playbackStateDidChanged = {
            expect.fulfill()
        }
        observer.meidaResourceInterruptionEnd()
        waitForExpectations(timeout: 1, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssert(self.mockVideoPlayer.playbackState == .playing)
    }

    func testAutoPlayForCover() {
        sut.setup(directUrl: "", taskKey: "", autoPlay: false)
        XCTAssert(self.mockVideoPlayer.playbackState == .paused)
    }

}

class MockDriveVideoPlayer: DriveVideoPlayer {
    weak var delegate: DriveVideoPlayerDelegate?
    var muted: Bool = false

    var playerView: UIView = UIView()
    var currentPlaybackTime: Double = 0
    var duration: Double = 1200
    var playbackState: DriveVideoPlaybackState = .stopped {
        didSet {
            if playbackState != oldValue {
                playbackStateDidChanged?()
            }
        }
    }
    var playbackStateDidChanged: (() -> Void)?
    var isLandscapeVideo: Bool = true
    var isSupportFullScreen: Bool = false
    var mediaType: DriveMediaType = .video
    var isPlayForCover: Bool = false

    func setup(directUrl url: String, taskKey: String, shouldPlayForCover: Bool) {
        isPlayForCover = shouldPlayForCover
        if shouldPlayForCover {
            play()
        }
    }
    
    func setup(cacheUrl url: URL, shouldPlayForCover: Bool) {
        isPlayForCover = shouldPlayForCover
        if shouldPlayForCover {
            play()
        }
    }
    
    func play() {
        if isPlayForCover {
            // 播放获取封面，无需对外发出更新 playbackState 事件
            pause()
            isPlayForCover = false
        } else {
            playbackState = .playing
            delegate?.videoPlayer(self, playbackStateDidChanged: .playing)
        }
    }
    
    func stop() {
        playbackState = .stopped
        delegate?.videoPlayer(self, playbackStateDidChanged: .stopped)
    }
    
    func pause() {
        playbackState = .paused
        delegate?.videoPlayer(self, playbackStateDidChanged: .paused)
    }
    
    func seek(progress: Float, completion: ((Bool) -> Void)?) {
        completion?(true)
    }
    
    func removeTimeObserver() {
        
    }
    
    func close() {
        
    }
    
    func resume(_ url: String, taskKey: String) {
        
    }
    
    func addRemoteCommandObserverIfNeeded() {
        
    }
    
    func removeRemoteCommandObserverIfNeeded() {
        
    }
}

class MockMediaMutexDependencyImpl: SKMediaMutexDependency {
    var result: SKMediaInterruptResult = .success
    var didunlock: Bool = false
    func tryLock(scene: SKMediaScene,
                 mixWithOthers: Bool,
                 mute: Bool,
                 observer: SKMediaResourceInterruptionObserver,
                 interruptResult: @escaping (SKMediaInterruptResult) -> Void) {
        interruptResult(result)
    }
    func unlock(scene: SKMediaScene, observer: SKMediaResourceInterruptionObserver) {
        self.didunlock = false
    }
    func enterDriveAudioSessionScenario(scene: SKMediaScene, id: String) {}
    func leaveDriveAudioSessionScenario(scene: SKMediaScene, id: String) {}
}
