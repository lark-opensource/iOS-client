//
//  FileSystem+Internal.swift
//  TTMicroApp
//
//  Created by Meng on 2021/8/5.
//

import Foundation
import ECOProbe
import ECOInfra

extension FileSystem {

    /// 标准 API 标识
    enum PrimitiveAPI: String {
        case unknown

        case fileExist
        case isDirectory
        case listContents
        case attributesOfFile
        case readFile
        case removeFile
        case moveFile
        case copyFile
        case writeFile
        case createDirectory
        case removeDirectory
        case canRead
        case canWrite
        case isOverSizeLimit

        case getSystemFile
        case copySystemFile
        case moveSystemFile
        case writeSystemData
        case unzip
        case decryptFile
        case appendFile

        var internalTag: String {
            return "__filesystem_\(rawValue)"
        }
    }

    static func monitorWrapper<T>(
        primitiveAPI: PrimitiveAPI,
        src: FileObject? = nil,
        dest: FileObject,
        context: Context,
        monitorOptimize: Bool = false,
        action: () throws -> T
    ) throws -> T {
        if !FileSystemUtils.isMonitorOptimizeDisable, monitorOptimize {
            context.trace.info("monitor optimize, call primitive API", additionalData: ["primitiveAPI": primitiveAPI.internalTag])
            do {
                return try action()
            } catch let error as FileSystemError {
                OPMonitor(EPMClientOpenPlatformInfraFileSystemCode.open_app_filesystem_primitive_api)
                    .setUniqueID(context.uniqueId)
                    .tracing(context.trace)
                    .addCategoryValue("primitive_api", primitiveAPI.rawValue)
                    .addCategoryValue("tag", context.tag)
                    .addCategoryValue("src_file_path", src?.base64RawValue)
                    .addCategoryValue("dest_file_path", dest.base64RawValue)
                    .addMap(error.categoryValue)
                    .setResultTypeFail()
                    .flush()
                throw error
            } catch {
                assertionFailure("could not run here!")
                throw error
            }
        }
        let monitor = OPMonitor(EPMClientOpenPlatformInfraFileSystemCode.open_app_filesystem_primitive_api)
            .setUniqueID(context.uniqueId)
            .tracing(context.trace)
            .addCategoryValue("primitive_api", primitiveAPI.rawValue)
            .addCategoryValue("tag", context.tag)
            .addCategoryValue("src_scheme", src?.url.scheme)
            .addCategoryValue("src_host", src?.url.host)
            .addCategoryValue("src_file_path", src?.base64RawValue)
            .addCategoryValue("dest_file_path", dest.base64RawValue)
            .addCategoryValue("src_file_path_length", src?.rawValue.count)
            .addCategoryValue("src_file_last_path_componment_length", src?.lastPathComponent.count)
            .addCategoryValue("src_file_extension", src?.pathExtension)
            .addCategoryValue("dest_scheme", dest.url.scheme)
            .addCategoryValue("dest_host", dest.url.host)
            .addCategoryValue("dest_file_path_length", dest.rawValue.count)
            .addCategoryValue("dest_file_last_path_componment_length", dest.lastPathComponent.count)
            .addCategoryValue("dest_file_extension", dest.pathExtension)
            .timing()

        extraMonitorBefore(src: src, dest: dest, context: context, monitor: monitor)
        do {
            let result = try action()
            extraMonitorAfter(src: src, dest: dest, context: context, monitor: monitor)
            monitor.setResultTypeSuccess().timing().flush()
            return result
        } catch let error as FileSystemError {
            monitor.addMap(error.categoryValue)
            extraMonitorAfter(src: src, dest: dest, context: context, monitor: monitor)
            monitor.setResultTypeFail().timing().flush()
            throw error
        } catch {
            assertionFailure("could not run here!")
            monitor.addCategoryValue("unrecognized_error", "\(error)")
            extraMonitorAfter(src: src, dest: dest, context: context, monitor: monitor)
            monitor.setResultTypeFail().timing().flush()
            throw error
        }
    }

    private static func extraMonitorBefore(src: FileObject?, dest: FileObject, context: Context, monitor: OPMonitor) {
        guard EMAFeatureGating.boolValue(forKey: "ecosystem.filesystem.extra_timing.before") else { return }

        do {
            let start = CACurrentMediaTime()
            if let src = src {
                let exists = try io.fileExists(src, context: context)
                monitor.addCategoryValue("src_file_exist_before", exists)
                if exists {
                    let attributes = try io.getFileInfo(src, autoDecrypt: false, context: context) as NSDictionary
                    let fileType = FileAttributeType(rawValue: attributes.fileType() ?? FileAttributeType.typeUnknown.rawValue)
                    monitor
                        .addCategoryValue("src_file_size_before", attributes.fileSize())
                        .addCategoryValue("src_file_type_before", fileType.monitorTypeString)
                }
            }

            let exists = try io.fileExists(dest, context: context)
            monitor.addCategoryValue("dest_file_exist_before", exists)
            if exists {
                let attributes = try io.getFileInfo(dest, autoDecrypt: false, context: context) as NSDictionary
                let fileType = FileAttributeType(rawValue: attributes.fileType() ?? FileAttributeType.typeUnknown.rawValue)
                monitor
                    .addCategoryValue("dest_file_size_before", attributes.fileSize())
                    .addCategoryValue("dest_file_type_before", fileType.monitorTypeString)
            }
            monitor.addCategoryValue("extra_info_timing_before", (CACurrentMediaTime() - start) * 1000)
        } catch let error as FileSystemError {
            monitor.addCategoryValue("extra_monitor_error_before", error.errorMessage)
        } catch {
            monitor.addCategoryValue("extra_monitor_unrecognized_error_before", "\(error)")
        }
    }

    private static func extraMonitorAfter(src: FileObject?, dest: FileObject, context: Context, monitor: OPMonitor) {
        guard EMAFeatureGating.boolValue(forKey: "ecosystem.filesystem.extra_timing.after") else { return }

        do {
            let start = CACurrentMediaTime()
            if let src = src {
                let exists = try io.fileExists(src, context: context)
                monitor.addCategoryValue("src_file_exist_after", exists)
                if exists {
                    let attributes = try io.getFileInfo(src, autoDecrypt: false, context: context) as NSDictionary
                    let fileType = FileAttributeType(rawValue: attributes.fileType() ?? FileAttributeType.typeUnknown.rawValue)
                    monitor
                        .addCategoryValue("src_file_size_after", attributes.fileSize())
                        .addCategoryValue("src_file_type_after", fileType.monitorTypeString)
                }
            }

            let exists = try io.fileExists(dest, context: context)
            monitor.addCategoryValue("dest_file_exist_after", exists)
            if exists {
                let attributes = try io.getFileInfo(dest, autoDecrypt: false, context: context) as NSDictionary
                let fileType = FileAttributeType(rawValue: attributes.fileType() ?? FileAttributeType.typeUnknown.rawValue)
                monitor
                    .addCategoryValue("dest_file_size_after", attributes.fileSize())
                    .addCategoryValue("dest_file_type_after", fileType.monitorTypeString)
            }
            monitor.addCategoryValue("extra_info_timing_after", (CACurrentMediaTime() - start) * 1000)
        } catch let error as FileSystemError {
            monitor.addCategoryValue("extra_monitor_error_after", error.errorMessage)
        } catch {
            monitor.addCategoryValue("extra_monitor_unrecognized_error_after", "\(error)")
        }
    }
}
