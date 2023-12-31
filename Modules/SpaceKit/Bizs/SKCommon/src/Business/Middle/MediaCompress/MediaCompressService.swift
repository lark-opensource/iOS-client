//
//  MediaCompressService.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/9/5.
//

import Foundation
import LKCommonsLogging
import Photos
import SpaceInterface
import SKUIKit
import SKFoundation

public final class MediaCompressService {
    static let logger = Logger.log(MediaCompressService.self, category: "MediaCompress.compressService")
    private let videoDurationLimited: TimeInterval = 300.0 //senconds
    private var startCompress: Bool = false
    let queue = DispatchQueue(label: "mediacompress.callback.queue")
    let dependency: MediaCompressDependency
    let mediaWriter: MediaWriter
    let cacheDir: SKFilePath // 保存中间文件存储目录
    init(dependency: MediaCompressDependency,
         cacheDir: SKFilePath,
         mediaWriter: MediaWriter = MediaWriterImpl()) {
        self.dependency = dependency
        self.cacheDir = cacheDir
        self.mediaWriter = mediaWriter
    }
    
    func cancelCompress(files: [MediaFile]) {
        self.queue.async { [weak self] in
            let taskIDs = files.map({ $0.taskID })
            self?.dependency.cancelCompress(taskIDs: taskIDs)
        }
    }
    
    func compress(files: [MediaFile], urlToken: String, writeToPathToken: String, isGifToken: String, complete: @escaping (DriveCompressStatus) -> Void) {
        // 存储所有文件的压缩进度，用于计算总进度
        var tasksProgress = [TaskID: Double]()
        // 关联taskID 和 file，方便快速存储
        var taskToFile = [TaskID: MediaFile]()
        var allFiles = files
        
        for index in 0..<allFiles.count {
            var file = allFiles[index]
            let path = self.exportURL(file: file, cacheDir: cacheDir, isGifToken: isGifToken)
            allFiles[index].exportPath = path
            file.exportPath = path
            tasksProgress[file.taskID] = 0.0
            taskToFile[file.taskID] = file
        }

        var results = [MediaResult]()
        for file in allFiles {
            guard let exportPath = file.exportPath else {
                Self.logger.info("no export path taskID: \(file.taskID)")
                continue
            }
            if file.isVideo {
                Self.logger.info("start compress video task id \(file.taskID)")
                guard file.asset.duration < videoDurationLimited else {
                    Self.logger.info(logId: "video duration over 5 min, dont compress")
                    self.saveOriginFile(file, tasksProgress: &tasksProgress, results: &results, writeToPathToken: writeToPathToken, isGifToken: isGifToken, complete: complete)
                    continue
                }
                MediaCompressHelper.getURL(from: file.asset, urlToken: urlToken) {[weak self] result in
                    guard let self = self else {
                        Self.logger.info("self deinit compress video not start task id \(file.taskID)")
                        return
                    }
                    switch result {
                    case let .success(url):
                        let videoSize = MediaCompressHelper.resolutionSizeForLocalVideo(url: url)
                        let videoInfo = DriveVideoParseInfo(originPath: url, exportPath: exportPath.pathURL, videoSize: videoSize)
                        self.handleStart(complete: complete)
                        self.dependency.compressVideo(videoParseInfo: videoInfo,
                                                 taskID: file.taskID,
                                                 complete: {[weak self] status in
                            guard let self = self else {
                                return
                            }
                            self.queue.async {
                                self.handleVideoResult(status,
                                                       taskToFile: taskToFile,
                                                       tasksProgress: &tasksProgress,
                                                       results: &results,
                                                       writeToPathToken: writeToPathToken,
                                                       isGifToken: isGifToken,
                                                       complete: complete)
                            }
                        })
                    case let .failure(error):
                        Self.logger.error("compress failed  taskID: \(file.taskID)", error: error)
                        self.saveOriginFile(file, tasksProgress: &tasksProgress, results: &results, writeToPathToken: writeToPathToken, isGifToken: isGifToken, complete: complete)
                    }
                }
                
            } else {
                if MediaCompressHelper.isGIFType(asset: file.asset, isGifToken: isGifToken) {
                    Self.logger.info("start compress GIF task id \(file.taskID)")
                    handleStart(complete: complete)
                    self.queue.async {
                        guard let file = taskToFile[file.taskID] else {
                            return
                        }
                        self.handleGIFResult(file, tasksProgress: &tasksProgress, results: &results, writeToPathToken: writeToPathToken, isGifToken: isGifToken, complete: complete)
                    }
                } else {
                    Self.logger.info("start compress image task id \(file.taskID)")
                    handleStart(complete: complete)
                    dependency.compressImage(asset: file.asset,
                                             taskID: file.taskID,
                                             complete: {[weak self] result in
                        guard let self = self else {
                            return
                        }
                        self.queue.async {
                            guard let file = taskToFile[result.taskID] else {
                                return
                            }
                            self.handleImageResult(result, file: file, tasksProgress: &tasksProgress, results: &results, isGifToken: isGifToken, complete: complete)
                        }
                    })
                }
            }
        }
    }
    
    private func handleStart(complete: (DriveCompressStatus) -> Void) {
        if !startCompress {
            startCompress = true
            complete(.start)
        }
    }
    
    private func handleVideoResult(_ result: CompressVideoStatus,
                                   taskToFile: [TaskID: MediaFile],
                                   tasksProgress: inout [TaskID: Double],
                                   results: inout [MediaResult],
                                   writeToPathToken: String,
                                   isGifToken: String,
                                   complete: (DriveCompressStatus) -> Void) {
        switch result {
        case let .success(taskID):
            guard let file = taskToFile[taskID], let exportPath = file.exportPath else {
                complete(.failed)
                return
            }
            guard let result = getVideoResult(from: file, isCompress: true) else {
                complete(.failed)
                return
            }
            results.append(result)
            tasksProgress[taskID] = 1.0
            if self.allTaskSuccess(tasksProgress) {
                Self.logger.info("taskID: \(taskID), video succsss")
                complete(.success(result: results))
            } else {
                let progress = self.allTaskProgress(tasksProgress)
                Self.logger.info("taskID: \(taskID), video succsss, total progress \(progress)")
                complete(.progress(progress: progress))
            }
        case let .progress(curProgress, taskID):
            tasksProgress[taskID] = curProgress
            let progress = self.allTaskProgress(tasksProgress)
            Self.logger.info("taskID: \(taskID), video total progress \(progress)")
            complete(.progress(progress: progress))
        case let .failed(msg, taskID):
            Self.logger.info("taskID: \(taskID), compress failed msg \(msg)")
            guard let file = taskToFile[taskID] else {
                Self.logger.info("taskID: \(taskID), no taskfile")
                complete(.failed)
                return
            }
            self.saveOriginFile(file, tasksProgress: &tasksProgress, results: &results, writeToPathToken: writeToPathToken, isGifToken: isGifToken, complete: complete)
        }
    }
    
    private func handleImageResult(_ result: CompressImageResult,
                                   file: MediaFile,
                                   tasksProgress: inout [TaskID: Double],
                                   results: inout [MediaResult],
                                   isGifToken: String,
                                   complete: (DriveCompressStatus) -> Void) {
        guard let exportPath = file.exportPath else {
            Self.logger.info("compress image failed no export path taskID: \(file.taskID)")
            complete(.failed)
            return
        }
        guard result.image != nil || result.data != nil else {
            Self.logger.error("compress image failed no compressed result taskID: \(file.taskID)")
            complete(.failed)
            return
        }
        let saveResult = self.mediaWriter.save(imageResult: result, to: exportPath)
        switch saveResult {
        case let .failure(error):
            Self.logger.error("save image result failed taskID: \(file.taskID)", error: error)
            complete(.failed)
        case .success(_):
            guard let imageResult = self.getImageResult(from: file, isCompress: true, isGifToken: isGifToken) else {
                Self.logger.error("no image result taskID: \(file.taskID)")
                return
            }
            tasksProgress[result.taskID] = 1
            let progress = self.allTaskProgress(tasksProgress)
            results.append(imageResult)
            if self.allTaskSuccess(tasksProgress) {
                Self.logger.info("compress image taskID: \(result.taskID), image succsss")
                complete(.success(result: results))
            } else {
                Self.logger.info("compress image taskID: \(result.taskID), image total progress \(progress)")
                complete(.progress(progress: progress))
            }
        }
    }
        
    private func handleGIFResult(_ file: MediaFile,
                                   tasksProgress: inout [TaskID: Double],
                                  results: inout [MediaResult],
                                  writeToPathToken: String,
                                 isGifToken: String,
                                   complete: (DriveCompressStatus) -> Void) {
        guard let exportPath = file.exportPath else {
            Self.logger.info("compress GIF failed no export path taskID: \(file.taskID)")
            complete(.failed)
            return
        }
        let saveResult = self.mediaWriter.saveOrigin(asset: file.asset, to: exportPath, writeToPathToken: writeToPathToken)
        guard let imageResult = self.getImageResult(from: file, isCompress: true, isGifToken: isGifToken) else {
                Self.logger.error("no image result taskID: \(file.taskID)")
                return
            }
            tasksProgress[file.taskID] = 1
            let progress = self.allTaskProgress(tasksProgress)
            results.append(imageResult)
            if self.allTaskSuccess(tasksProgress) {
                Self.logger.info("compress image taskID: \(file.taskID), image succsss")
                complete(.success(result: results))
            } else {
                Self.logger.info("compress image taskID: \(file.taskID), image total progress \(progress)")
                complete(.progress(progress: progress))
            }
    }
    
    private func getImageResult(from file: MediaFile, isCompress: Bool, isGifToken: String) -> MediaResult? {
        guard let exportPath = file.exportPath else {
            Self.logger.error("no export path taskID: \(file.taskID)")
            return nil
        }
        let fileName = MediaCompressHelper.getImageNames(from: file.asset, compress: isCompress, isGifToken: isGifToken).originName
        let fileSize = exportPath.fileSize ?? 0
        let imageSize = SKImagePreviewUtils.originSizeOfImage(path: exportPath) ?? CGSize.zero
        Self.logger.info("image fileSize: \(fileSize), imageSize: \(imageSize), taskID: \(file.taskID)")
        return MediaResult.image(result: ImageResult(exportURL: exportPath.pathURL,
                                                     name: fileName,
                                                     fileSize: fileSize,
                                                     imageSize: imageSize,
                                                     taskID: file.taskID))
        
    }
    
    private func getVideoResult(from file: MediaFile, isCompress: Bool) -> MediaResult? {
        guard let exportPath = file.exportPath else {
            Self.logger.error("no export path")
            return nil
        }
        let fileName = MediaCompressHelper.getVideoName(from: file.asset, compress: isCompress).originName
        let fileSize = exportPath.fileSize ?? 0
        let duration = file.asset.duration
        let videoSize = MediaCompressHelper.resolutionSizeForLocalVideo(url: exportPath.pathURL)
        return MediaResult.video(result: VideoResult(exportURL: exportPath.pathURL,
                                                     name: fileName,
                                                     fileSize: fileSize,
                                                     videoSize: videoSize,
                                                     duraion: duration,
                                                     taskID: file.taskID))
    }
    
    private func allTaskProgress(_ tasksProgress: [String: Double]) -> Double {
        let count = Double(tasksProgress.count)
        var progress: Double = 0.0
        for p in tasksProgress.values {
            progress += (p / count)
        }
        return progress
    }
    
    private func allTaskSuccess(_ tasksProgress: [String: Double]) -> Bool {
        for p in tasksProgress.values {
            if fabs(p - 1.0) > Double.ulpOfOne {
                return false
            }
        }
        return true
    }
    
    private func exportURL(file: MediaFile, cacheDir: SKFilePath, isGifToken: String) -> SKFilePath {
        var savedName: String = ""
        if file.isVideo {
            (savedName, _) = MediaCompressHelper.getVideoName(from: file.asset, compress: true)

        } else {
            (savedName, _) = MediaCompressHelper.getImageNames(from: file.asset, compress: true, isGifToken: isGifToken)
        }
        let exportPath = cacheDir.appendingRelativePath(savedName)
        return exportPath
    }
    
    // save origin file
    private func saveOriginFile(_ file: MediaFile,
                                tasksProgress: inout [TaskID: Double],
                                results: inout [MediaResult],
                                writeToPathToken: String,
                                isGifToken: String,
                                complete: (DriveCompressStatus) -> Void) {
        Self.logger.info("taskID: \(file.taskID) start saving origin file")
        guard let exportPath = file.exportPath else {
            Self.logger.error("no export path taskID: \(file.taskID)")
            complete(.failed)
            return
        }
        let saveResult = self.mediaWriter.saveOrigin(asset: file.asset, to: exportPath, writeToPathToken: writeToPathToken)
        switch saveResult {
        case .success(_):
            if file.isVideo {
                guard let videoResult = getVideoResult(from: file, isCompress: false) else {
                    Self.logger.error("can not get video result taskID: \(file.taskID)")
                    complete(.failed)
                    return
                }
                Self.logger.info("taskID: \(file.taskID) did saved origin video")
                results.append(videoResult)
            } else {
                guard let imageResult = getImageResult(from: file, isCompress: false, isGifToken: isGifToken) else {
                    Self.logger.error("can not get image result taskID: \(file.taskID)")
                    complete(.failed)
                    return
                }
                Self.logger.info("taskID: \(file.taskID) did saved origin image")
                results.append(imageResult)
            }
            tasksProgress[file.taskID] = 1
            let progress = self.allTaskProgress(tasksProgress)
            if self.allTaskSuccess(tasksProgress) {
                Self.logger.info("compress image taskID: \(file.taskID), image succsss")
                complete(.success(result: results))
            } else {
                Self.logger.info("compress image taskID: \(file.taskID), image progress \(progress)")
                complete(.progress(progress: progress))
            }
        case let .failure(error):
            Self.logger.error("save origin file failed taskID: \(file.taskID)", error: error)
            complete(.failed)
            
        }
    }
}
