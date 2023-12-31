//
//  DrivePreviewCellVMTest.swift
//  DocsTests
//
//  Created by bupozhuang on 2019/12/2.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import SpaceKit
//swiftlint:disable function_body_length
class DrivePreviewCellVMTest: QuickSpec {
    var fileInfo = DriveFileInfo.fileInfo(with: fileInfoNoServerTransfromJson)!
    let docsInfo = DocsInfo(type: .file, objToken: "xxxx")
    let cacheService = DriveCacheServiceMocker()
    let netMonitor = MockNetStatusMonitor()
    let download = MockDownloadHelper()
    var permission = DrivePermissionMocker()
    let pushHandler = DrivePreviewPushMocker()

    lazy var netManager = DriveNetWorkMocker(docsInfo: self.docsInfo, fileInfo: self.fileInfo, previews: [])

    override func spec() {
        describe("预览") {
            var vm: DrivePreviewCellViewModelType!
            let perfermance = DrivePerformanceRecorder(fileToken: self.fileInfo.fileToken, fileType: self.fileInfo.type, sourceType: .other)
            beforeEach {
                self.fileInfo = DriveFileInfo.fileInfo(with: fileInfoNoServerTransfromJson)!
                self.permission = DrivePermissionMocker()
            }
            it("无网络，没有cache的情况:startloading->exitPreviewWithHUD->endloading", closure: {
                vm = DrivePreviewCellViewModel(with: self.fileInfo,
                                               docsInfo: self.docsInfo,
                                               performanceLogger: perfermance,
                                               context: self.context(),
                                               dependences: self.configDependencesNoNetNoCahce())
                var actions: [ViewModelAction] = [ViewModelAction]()
                vm.bindAction = { event in
                    actions.append(event)
                }
                vm.setupPreviewData()
                expect(actions.count).toEventually(equal(5), timeout: 1.0)
                expect(actions[0]).toEventually(equal(ViewModelAction.startLoading), timeout: 1.0)
                expect(actions[1]).toEventually(equal(ViewModelAction.exitPreviewWithHUD(msg: BundleI18n.SKResource.Drive_Drive_NetInterrupt)),
                                                timeout: 1.0)
                expect(actions[2]).toEventually(equal(ViewModelAction.endLoading), timeout: 1.0)
                expect(actions[3]).toEventually(equal(ViewModelAction.userPermissionChanged), timeout: 1.0)
                expect(actions[4]).toEventually(equal(ViewModelAction.publicPermissionChanged), timeout: 1.0)
            })
            it("无网络，有cache的情况:startloading->startOpenFile->directOpenCacheFile->endloading", closure: {
                vm = DrivePreviewCellViewModel(with: self.fileInfo,
                                               docsInfo: self.docsInfo,
                                               performanceLogger: perfermance,
                                               context: self.context(),
                                               dependences: self.configDependencesNoNetHasCahce())
                var actions: [ViewModelAction] = [ViewModelAction]()
                vm.bindAction = { event in
                    actions.append(event)
                }
                vm.setupPreviewData()
                expect(actions.count).toEventually(equal(6), timeout: 1.0)
                expect(actions[0]).toEventually(equal(ViewModelAction.startLoading), timeout: 1.0)
                expect(actions[1]).toEventually(equal(ViewModelAction.startOpenFile), timeout: 1.0)
                expect(actions[2]).toEventually(equal(ViewModelAction.directOpenCacheFile(fileMeta: self.fileInfo.getFileMeta())),
                                                timeout: 1.0)
                expect(actions[3]).toEventually(equal(ViewModelAction.endLoading), timeout: 1.0)
                expect(actions[4]).toEventually(equal(ViewModelAction.userPermissionChanged), timeout: 1.0)
                expect(actions[5]).toEventually(equal(ViewModelAction.publicPermissionChanged), timeout: 1.0)
            })
            it("有网络，无缓存，正常打开非转码文件流程:startloading->downloading->startOpenFile->downloadCompleted->endloading", closure: {
                vm = DrivePreviewCellViewModel(with: self.fileInfo,
                                               docsInfo: self.docsInfo,
                                               performanceLogger: perfermance,
                                               context: self.context(),
                                               dependences: self.configDependencesNoCahceOnline())
                var actions: [ViewModelAction] = [ViewModelAction]()
                vm.bindAction = { event in
                    actions.append(event)
                }
                vm.setupPreviewData()
                expect(actions.count).toEventually(equal(7), timeout: 1.0)
                expect(actions[0]).toEventually(equal(ViewModelAction.startLoading), timeout: 1.0)
                expect(actions[1]).toEventually(equal(ViewModelAction.downloading(progress: 0)), timeout: 1.0)
                expect(actions[2]).toEventually(equal(ViewModelAction.startOpenFile), timeout: 1.0)
                expect(actions[3]).toEventually(equal(ViewModelAction.downloadCompleted), timeout: 1.0)
                expect(actions[4]).toEventually(equal(ViewModelAction.endLoading), timeout: 1.0)
                expect(actions[5]).toEventually(equal(ViewModelAction.userPermissionChanged), timeout: 1.0)
                expect(actions[6]).toEventually(equal(ViewModelAction.publicPermissionChanged), timeout: 1.0)
            })

            it("有网络，无缓存，正常打开video转码文件流程:startloading->driveTranscoding->startOpenFile->readyForDriveVideoPlayer->endloading", closure: {
                self.fileInfo = DriveFileInfo.fileInfo(with: videoFileInfoJson)!
                let preview = DriveFilePreview.preview(with: videoPreviewReadyJson)!
                vm = DrivePreviewCellViewModel(with: self.fileInfo,
                                               docsInfo: self.docsInfo,
                                               performanceLogger: perfermance,
                                               context: self.context(),
                                               dependences: self.configDependencesPreviewVideoNoCache())
                var actions: [ViewModelAction] = [ViewModelAction]()
                vm.bindAction = { event in
                    actions.append(event)
                }
                vm.setupPreviewData()
                expect(actions.count).toEventually(equal(7), timeout: 1.0)
                expect(actions[0]).toEventually(equal(ViewModelAction.startLoading), timeout: 1.0)
                expect(actions[1]).toEventually(equal(ViewModelAction.driveTranscoding(false)), timeout: 1.0)
                expect(actions[2]).toEventually(equal(ViewModelAction.startOpenFile), timeout: 1.0)
                expect(actions[3]).toEventually(equal(ViewModelAction.readyForDriveVideoPlayer(videoInfo: preview.videoInfo!)), timeout: 1.0)
                expect(actions[4]).toEventually(equal(ViewModelAction.endLoading), timeout: 1.0)
                expect(actions[5]).toEventually(equal(ViewModelAction.userPermissionChanged), timeout: 1.0)
                expect(actions[6]).toEventually(equal(ViewModelAction.publicPermissionChanged), timeout: 1.0)
            })
            it("有网络，有缓存，正常打开video转码文件流程:startloading->driveTranscoding->startOpenFile->readyForDriveVideoPlayer->endloading", closure: {
                self.fileInfo = DriveFileInfo.fileInfo(with: videoFileInfoJson)!
                let preview = DriveFilePreview.preview(with: videoPreviewReadyJson)!
                vm = DrivePreviewCellViewModel(with: self.fileInfo,
                                               docsInfo: self.docsInfo,
                                               performanceLogger: perfermance,
                                               context: self.context(),
                                               dependences: self.configDependencesPreviewVideoCached())
                var actions: [ViewModelAction] = [ViewModelAction]()
                vm.bindAction = { event in
                    actions.append(event)
                }
                vm.setupPreviewData()
                expect(actions.count).toEventually(equal(7), timeout: 1.0)
                expect(actions[0]).toEventually(equal(ViewModelAction.startLoading), timeout: 1.0)
                expect(actions[1]).toEventually(equal(ViewModelAction.driveTranscoding(false)), timeout: 1.0)
                expect(actions[2]).toEventually(equal(ViewModelAction.startOpenFile), timeout: 1.0)
                expect(actions[3]).toEventually(equal(ViewModelAction.readyForDriveVideoPlayer(videoInfo: preview.videoInfo!)), timeout: 1.0)
                expect(actions[4]).toEventually(equal(ViewModelAction.endLoading), timeout: 1.0)
                expect(actions[5]).toEventually(equal(ViewModelAction.userPermissionChanged), timeout: 1.0)
                expect(actions[6]).toEventually(equal(ViewModelAction.publicPermissionChanged), timeout: 1.0)
            })

            it("有网络，无缓存，转码中显示转码中:startloading->driveTranscoding->startOpenFile", closure: {
                self.fileInfo = DriveFileInfo.fileInfo(with: videoFileInfoJson)!
                vm = DrivePreviewCellViewModel(with: self.fileInfo,
                                               docsInfo: self.docsInfo,
                                               performanceLogger: perfermance,
                                               context: self.context(),
                                               dependences: self.configDependencesPreviewVideoGenerating())
                var actions: [ViewModelAction] = [ViewModelAction]()
                vm.bindAction = { event in
                    actions.append(event)
                }
                vm.setupPreviewData()
                expect(actions.count).toEventually(equal(4), timeout: 1.0)
                expect(actions[0]).toEventually(equal(ViewModelAction.startLoading), timeout: 1.0)
                expect(actions[1]).toEventually(equal(ViewModelAction.driveTranscoding(true)), timeout: 1.0)
                expect(actions[2]).toEventually(equal(ViewModelAction.userPermissionChanged), timeout: 1.0)
                expect(actions[3]).toEventually(equal(ViewModelAction.publicPermissionChanged), timeout: 1.0)
            })

            it("有网络，无缓存，转码失败下载源文件:startloading->driveTranscoding->downloading->startOpenFile->downloadCompleted->endLoading", closure: {
                self.fileInfo = DriveFileInfo.fileInfo(with: videoFileInfoJson)!
                vm = DrivePreviewCellViewModel(with: self.fileInfo,
                                               docsInfo: self.docsInfo,
                                               performanceLogger: perfermance,
                                               context: self.context(),
                                               dependences: self.configDependencesPreviewVideoGenerateFailed())
                var actions: [ViewModelAction] = [ViewModelAction]()
                vm.bindAction = { event in
                    actions.append(event)
                }
                vm.setupPreviewData()
                expect(actions.count).toEventually(equal(8), timeout: 1.0)
                expect(actions[0]).toEventually(equal(ViewModelAction.startLoading), timeout: 1.0)
                expect(actions[1]).toEventually(equal(ViewModelAction.driveTranscoding(false)), timeout: 1.0)
                expect(actions[2]).toEventually(equal(ViewModelAction.downloading(progress: 0.0)), timeout: 1.0)
                expect(actions[3]).toEventually(equal(ViewModelAction.startOpenFile), timeout: 1.0)
                expect(actions[4]).toEventually(equal(ViewModelAction.downloadCompleted), timeout: 1.0)
                expect(actions[5]).toEventually(equal(ViewModelAction.endLoading), timeout: 1.0)
                expect(actions[6]).toEventually(equal(ViewModelAction.userPermissionChanged), timeout: 1.0)
                expect(actions[7]).toEventually(equal(ViewModelAction.publicPermissionChanged), timeout: 1.0)
            })

            it("有网络，无缓存，fg关闭, 打开zip文件:startloading->driveTranscoding->startOpenFile->showUnsupportView->endloading", closure: {
                self.fileInfo = DriveFileInfo.fileInfo(with: zipFileInfoJson)!
                vm = DrivePreviewCellViewModel(with: self.fileInfo,
                                               docsInfo: self.docsInfo,
                                               performanceLogger: perfermance,
                                               context: self.context(),
                                               dependences: self.configDependencesPreviewZip())
                var actions: [ViewModelAction] = [ViewModelAction]()
                vm.bindAction = { event in
                    actions.append(event)
                }
                vm.setupPreviewData()
                expect(actions.count).toEventually(equal(7), timeout: 1.0)
                expect(actions[0]).toEventually(equal(ViewModelAction.startLoading), timeout: 1.0)
                expect(actions[1]).toEventually(equal(ViewModelAction.driveTranscoding(false)), timeout: 1.0)
                expect(actions[2]).toEventually(equal(ViewModelAction.startOpenFile), timeout: 1.0)
                expect(actions[3]).toEventually(equal(ViewModelAction.showUnsupportView(type: DriveUnsupportPreviewType.typeUnsupport)),
                                                timeout: 1.0)
                expect(actions[4]).toEventually(equal(ViewModelAction.endLoading), timeout: 1.0)
                expect(actions[5]).toEventually(equal(ViewModelAction.userPermissionChanged), timeout: 1.0)
                expect(actions[6]).toEventually(equal(ViewModelAction.publicPermissionChanged), timeout: 1.0)
            })

            it("有网络，有缓存，打开zip文件", closure: {
            })
            it("无网络，有缓存，打开zip文件", closure: {
            })
            it("有网络，无缓存，打开正常txt文件", closure: {
            })
            it("有网络，无缓存，打开超大txt文件", closure: {
            })
            it("无网络，有缓存，打开超大txt文件", closure: {
            })
            it("有网络，无缓存，打开审核不通过文件", closure: {
            })
            it("有网络，无缓存，打开sketch文件", closure: {
            })
            it("有网络，无缓存，打开不支持文件", closure: {
            })
            it("无网络，有缓存，打开不支持文件", closure: {
            })
            it("4G网络，无缓存，打开超出大小文件", closure: {
            })
            
        }
    }
}

extension DrivePreviewCellVMTest {
    // 无网络无cache
    private func configDependencesNoNetNoCahce() -> DrivePreviewCellViewModelDependences {
        self.cacheService.config(videoFileExist: false, originFileNode: nil, previewFileNode: nil)
        self.netMonitor.changeAccessType(.notReachable)
        return DrivePreviewCellViewModelDependences(cacheService: cacheService,
                                                    downloadHelper: download,
                                                    networkMonitor: netMonitor,
                                                    permissionHelperFactory: { (_, _) -> DrivePermissionHelperProtocol in
            return self.permission as DrivePermissionHelperProtocol
        }, netManagerFactory: { (_, _) -> DrivePreviewNetManagerProtocol in
            return self.netManager as DrivePreviewNetManagerProtocol
        }, previewGetPushHandlerFactory: { (_) -> DrivePreviewGetPushService in
            return self.pushHandler as DrivePreviewGetPushService
        })
    }
    // 无网络有cache
    private func configDependencesNoNetHasCahce() -> DrivePreviewCellViewModelDependences {
        let node = DriveCacheFileNode(key: "testKey",
                                 fileName: "testname",
                                 originFileName: "testOriginName",
                                 fileRootURL: URL(fileURLWithPath: "/cc/"),
                                 fileSize: 1_024, version: "testversion")
        self.netMonitor.changeAccessType(.notReachable)
        self.cacheService.config(videoFileExist: true, originFileNode: node, previewFileNode: node)
        return DrivePreviewCellViewModelDependences(cacheService: cacheService,
                                                    downloadHelper: download,
                                                    networkMonitor: netMonitor,
                                                    permissionHelperFactory: { (_, _) -> DrivePermissionHelperProtocol in
            return self.permission as DrivePermissionHelperProtocol
        }, netManagerFactory: { (_, _) -> DrivePreviewNetManagerProtocol in
            return self.netManager as DrivePreviewNetManagerProtocol
        }, previewGetPushHandlerFactory: { (_) -> DrivePreviewGetPushService in
            return self.pushHandler as DrivePreviewGetPushService
        })
    }

    // 有网络无cache
    private func configDependencesNoCahceOnline() -> DrivePreviewCellViewModelDependences {
        self.cacheService.config(videoFileExist: false, originFileNode: nil, previewFileNode: nil)
        self.download.configDownloadStatus(false, isForbid: false)
        self.netMonitor.changeAccessType(.wifi)
        return DrivePreviewCellViewModelDependences(cacheService: cacheService,
                                                    downloadHelper: download,
                                                    networkMonitor: netMonitor,
                                                    permissionHelperFactory: { (_, _) -> DrivePermissionHelperProtocol in
            return self.permission as DrivePermissionHelperProtocol
        }, netManagerFactory: { (_, _) -> DrivePreviewNetManagerProtocol in
            return self.netManager as DrivePreviewNetManagerProtocol
        }, previewGetPushHandlerFactory: { (_) -> DrivePreviewGetPushService in
            return self.pushHandler as DrivePreviewGetPushService
        })
    }

    // 有网络，无cache，预览转码video
    private func configDependencesPreviewVideoNoCache() -> DrivePreviewCellViewModelDependences {
        self.cacheService.config(videoFileExist: false, originFileNode: nil, previewFileNode: nil)
        self.download.configDownloadStatus(false, isForbid: false)
        self.netMonitor.changeAccessType(.wifi)
        let preview = DriveFilePreview.preview(with: videoPreviewReadyJson)!
        self.netManager.config(requestTime: 0, docsInfo: self.docsInfo, fileInfo: self.fileInfo, previews: [preview])
        return DrivePreviewCellViewModelDependences(cacheService: cacheService,
                                                    downloadHelper: download,
                                                    networkMonitor: netMonitor,
                                                    permissionHelperFactory: { (_, _) -> DrivePermissionHelperProtocol in
            return self.permission as DrivePermissionHelperProtocol
        }, netManagerFactory: { (_, _) -> DrivePreviewNetManagerProtocol in
            return self.netManager as DrivePreviewNetManagerProtocol
        }, previewGetPushHandlerFactory: { (_) -> DrivePreviewGetPushService in
            return self.pushHandler as DrivePreviewGetPushService
        })
    }
    // 有网络，有cache，预览转码video
    private func configDependencesPreviewVideoCached() -> DrivePreviewCellViewModelDependences {
        self.cacheService.config(videoFileExist: true, originFileNode: nil, previewFileNode: nil)
        self.download.configDownloadStatus(false, isForbid: false)
        self.netMonitor.changeAccessType(.wifi)
        let preview = DriveFilePreview.preview(with: videoPreviewReadyJson)!
        self.netManager.config(requestTime: 0, docsInfo: self.docsInfo, fileInfo: self.fileInfo, previews: [preview])
        return DrivePreviewCellViewModelDependences(cacheService: cacheService,
                                                    downloadHelper: download,
                                                    networkMonitor: netMonitor,
                                                    permissionHelperFactory: { (_, _) -> DrivePermissionHelperProtocol in
            return self.permission as DrivePermissionHelperProtocol
        }, netManagerFactory: { (_, _) -> DrivePreviewNetManagerProtocol in
            return self.netManager as DrivePreviewNetManagerProtocol
        }, previewGetPushHandlerFactory: { (_) -> DrivePreviewGetPushService in
            return self.pushHandler as DrivePreviewGetPushService
        })
    }

    // 有网络，无cache，预览转码中
    private func configDependencesPreviewVideoGenerating() -> DrivePreviewCellViewModelDependences {
        self.cacheService.config(videoFileExist: false, originFileNode: nil, previewFileNode: nil)
        self.download.configDownloadStatus(false, isForbid: false)
        self.netMonitor.changeAccessType(.wifi)
        let preview = DriveFilePreview.preview(with: videoPreviewGenerartingJson)!
        self.netManager.config(requestTime: 0, docsInfo: self.docsInfo, fileInfo: self.fileInfo, previews: [preview])
        return DrivePreviewCellViewModelDependences(cacheService: cacheService,
                                                    downloadHelper: download,
                                                    networkMonitor: netMonitor,
                                                    permissionHelperFactory: { (_, _) -> DrivePermissionHelperProtocol in
            return self.permission as DrivePermissionHelperProtocol
        }, netManagerFactory: { (_, _) -> DrivePreviewNetManagerProtocol in
            return self.netManager as DrivePreviewNetManagerProtocol
        }, previewGetPushHandlerFactory: { (_) -> DrivePreviewGetPushService in
            return self.pushHandler as DrivePreviewGetPushService
        })
    }

    // 有网络，无cache，预览转码失败
    private func configDependencesPreviewVideoGenerateFailed() -> DrivePreviewCellViewModelDependences {
        self.cacheService.config(videoFileExist: false, originFileNode: nil, previewFileNode: nil)
        self.download.configDownloadStatus(false, isForbid: false)
        self.netMonitor.changeAccessType(.wifi)
        let preview = DriveFilePreview.preview(with: videoPreviewFailedJson)!
        self.netManager.config(requestTime: 0, docsInfo: self.docsInfo, fileInfo: self.fileInfo, previews: [preview])
        return DrivePreviewCellViewModelDependences(cacheService: cacheService,
                                                    downloadHelper: download,
                                                    networkMonitor: netMonitor,
                                                    permissionHelperFactory: { (_, _) -> DrivePermissionHelperProtocol in
            return self.permission as DrivePermissionHelperProtocol
        }, netManagerFactory: { (_, _) -> DrivePreviewNetManagerProtocol in
            return self.netManager as DrivePreviewNetManagerProtocol
        }, previewGetPushHandlerFactory: { (_) -> DrivePreviewGetPushService in
            return self.pushHandler as DrivePreviewGetPushService
        })
    }
    // 有网络，无cache，zip
    private func configDependencesPreviewZip() -> DrivePreviewCellViewModelDependences {
        self.cacheService.config(videoFileExist: false, originFileNode: nil, previewFileNode: nil)
        self.download.configDownloadStatus(false, isForbid: false)
        self.netMonitor.changeAccessType(.wifi)
        let preview = DriveFilePreview.preview(with: zipPreviewJson)!
        self.netManager.config(requestTime: 0, docsInfo: self.docsInfo, fileInfo: self.fileInfo, previews: [preview])
        return DrivePreviewCellViewModelDependences(cacheService: cacheService,
                                                    downloadHelper: download,
                                                    networkMonitor: netMonitor,
                                                    permissionHelperFactory: { (_, _) -> DrivePermissionHelperProtocol in
            return self.permission as DrivePermissionHelperProtocol
        }, netManagerFactory: { (_, _) -> DrivePreviewNetManagerProtocol in
            return self.netManager as DrivePreviewNetManagerProtocol
        }, previewGetPushHandlerFactory: { (_) -> DrivePreviewGetPushService in
            return self.pushHandler as DrivePreviewGetPushService
        })
    }

    private func context() -> DrivePreviewContext {
        let fileList = [DriveFileContext(fileMeta: fileInfo.getFileMeta(), docsInfo: docsInfo)]
        let configuration = DrivePreviewConfiguration(shouldShowRightItems: true, loadingView: nil, hitoryEditTimeStamp: nil)
        return DrivePreviewContext(fileList: fileList, configuration: configuration, fileResource: FileResource(), previewFrom: .docsList, bussinessID: nil, feedId: nil)
    }
}
