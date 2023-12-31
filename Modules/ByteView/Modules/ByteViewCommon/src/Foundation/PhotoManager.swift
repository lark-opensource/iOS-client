//
//  PhotoManager.swift
//  ByteViewCommon
//
//  Created by FakeGourmet on 2023/11/17.
//

import Foundation
import Photos
import LarkSensitivityControl

public final class PhotoManager {

    static let token = Token("LARK-PSDA-annotation_and_whiteboard_save_photo")

    public enum PhotoSaveError: Error {
        case unknown
        case running
    }

    public typealias PhotoSaveCompletion = (Result<Void, Error>) -> Void

    public static let shared: PhotoManager = PhotoManager()

    public func savePhoto(data: Data, completion: @escaping PhotoSaveCompletion) {
        save(type: .photo, datas: [data], completion: completion)
    }

    public func savePhotos(data: [Data], completion: @escaping PhotoSaveCompletion) {
        save(type: .photo, datas: data, completion: completion)
    }

    func save(type: PHAssetResourceType, datas: [Data], completion: @escaping PhotoSaveCompletion) {
        Self.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    for data in datas {
                        do {
                            let creationRequest = try AlbumEntry.forAsset(forToken: Self.token)
                            creationRequest.addResource(with: type, data: data, options: options)
                        } catch {

                        }
                    }
                }) { isSuccess, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else if isSuccess {
                            completion(.success(()))
                        } else {
                            completion(.failure(PhotoSaveError.unknown))
                        }
                    }
                }
            default:
                break
            }
        }
    }

    class func requestAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
        do {
            if #available(iOS 14, *) {
                try AlbumEntry.requestAuthorization(forToken: Self.token, forAccessLevel: .addOnly) { status in
                    completion(status)
                }
            } else {
                try AlbumEntry.requestAuthorization(forToken: Self.token) { status in
                    completion(status)
                }
            }
        } catch {
            completion(.notDetermined)
        }
    }
}
