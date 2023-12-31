//
//  AssetGridSingleSelectViewController.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/11.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import PhotosUI
import LarkSensitivityControl

final class AssetGridSingleSelectViewController: AssetGridBaseViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == currentAlbum.assetsCount && PhotoPickView.preventStyle == .limited {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectMoreCell.identifier, for: indexPath) as? SelectMoreCell else {
                return UICollectionViewCell()
            }
            return cell
        }
        let reuseID = String(describing: AssetGridCell.self)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseID, for: indexPath) as? AssetGridCell else {
            return UICollectionViewCell()
        }
        let asset = currentAlbum.asset(at: indexPath.item)
        cell.currentAsset = asset
        cell.showCheckButton = false
        cell.videoDuration = asset.duration

        let cellSize = calculateItemSize(containerSize: view.bounds.size)
        let targetSize = CGSize(width: cellSize.width * UIScreen.main.scale, height: cellSize.height * UIScreen.main.scale)
        _ = try? AlbumEntry.requestImage(forToken: AssetBrowserToken.requestImage.token,
                                         manager: imageManager,
                                         forAsset: asset,
                                         targetSize: targetSize,
                                         contentMode: .aspectFill,
                                         options: nil) { (image, _) in
            if cell.assetIdentifier ?? "" == asset.localIdentifier {
                cell.setImage(image)
                if let key = self.disposedKey {
                    AssetsPickerTracker.end(key: key)
                    self.disposedKey = nil
                }
            }
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == currentAlbum.assetsCount && PhotoPickView.preventStyle == .limited {
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            }
        } else {
            let asset = currentAlbum.asset(at: indexPath.item)
            deselectAllAssets()
            let image = (collectionView.cellForItem(at: indexPath) as? AssetGridCell)?.currentImage
            selectAsset(asset, image: image)
            finishSelect()
        }
    }
}
