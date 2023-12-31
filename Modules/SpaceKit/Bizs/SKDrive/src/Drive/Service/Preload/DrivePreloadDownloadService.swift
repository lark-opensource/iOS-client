//
//  DrivePreloadDownloadService.swift
//  SpaceKit
//
//  Created by Wenjian Wu on 2019/4/12.
//  

import Foundation
import SKCommon
import SKFoundation

protocol DrivePreloadDelegate: DrivePreloadOperationDelegate {
    func operation(_ operation: DrivePreloadOperation, didFinishedWithResult isSuccess: Bool)
}

class DrivePreloadDownloadService: NSObject {

    weak var delegate: DrivePreloadDelegate?
    private var preloadManageQueue: DispatchQueue
    private var preloadCallbackQueue: DispatchQueue
    private var preloadOperationQueue: OperationQueue
    private var operations: [String: DrivePreloadOperation]
    private var preloading: [String]
    private var observations: [String: NSKeyValueObservation]

    init(label: String) {
        preloadManageQueue = DispatchQueue(label: "DocsSDK.Drive.Preload.Manage.\(label)")
        preloadCallbackQueue = DispatchQueue(label: "DocsSDK.Drive.Preload.Callback.\(label)")
        preloadOperationQueue = OperationQueue()
        preloadOperationQueue.maxConcurrentOperationCount = 1
        preloading = []
        operations = [:]
        observations = [:]
        super.init()
    }

    func download(request: DrivePreloadService.Request, wikiToken: String? = nil) {
        let token = request.token
        preloadManageQueue.async {
            if self.preloading.contains(token) {
                return
            }
            self.preloading.append(token)
            DocsLogger.driveInfo("Drive.Preload.Manage---start Preloading for token: \(DocsTracker.encrypt(id: token))")
            let operation = DrivePreloadOperation(preloadRequest: request, callbackQueue: self.preloadCallbackQueue, cacheService: DriveCacheService.shared, wikiToken: wikiToken)
            operation.delegate = self
            let observation = operation.observe(\.isFinished, changeHandler: { (operation, _) in
                if operation.isFinished {
                    self.preloadManageQueue.async {
                        DocsLogger.debug("Drive.Preload.Manage --- preload finished for token: \(DocsTracker.encrypt(id: token))")
                        self.operations[token] = nil
                        self.observations[token] = nil
                        if let index = self.preloading.firstIndex(of: token) {
                            self.preloading.remove(at: index)
                        }
                        self.delegate?.operation(operation, didFinishedWithResult: operation.isSuccess)
                    }
                }
            })
            self.observations[token] = observation
            self.operations[token] = operation
            self.preloadOperationQueue.addOperation(operation)
        }
    }

    func cancel(token: String) {
        preloadManageQueue.async {
            guard let operation = self.operations[token] else {
                return
            }
            operation.cancel()
            self.operations[token] = nil
            guard let index = self.preloading.firstIndex(of: token) else {
                return
            }
            self.preloading.remove(at: index)
            DocsLogger.driveInfo("Drive.Preload.Manage---Preload cancel for token: \(DocsTracker.encrypt(id: token))")
        }
    }
}

extension DrivePreloadDownloadService: DrivePreloadOperationDelegate {
    func operation(_ operation: DrivePreloadOperation, updateFileInfo fileInfo: DriveFileInfo) {
        self.delegate?.operation(operation, updateFileInfo: fileInfo)
    }

    func operation(_ operation: DrivePreloadOperation, failedWithError error: DrivePreloadOperation.PreloadError) {
        self.delegate?.operation(operation, failedWithError: error)
    }
}
