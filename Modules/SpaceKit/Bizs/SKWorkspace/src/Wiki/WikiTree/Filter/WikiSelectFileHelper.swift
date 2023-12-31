//
//  WikiSelectFileHelper.swift
//  SKWikiV2
//
//  Created by bupozhuang on 2021/8/3.
//

import Foundation
import SKCommon
import SKFoundation
import LarkUIKit
import EENavigator
import RxSwift
import RxCocoa
import UniverseDesignToast
import SKResource
import SpaceInterface
import SKInfra

public class WikiSelectFileHelper {
    weak var hostViewController: UIViewController?
    let triggerLocation: WikiStatistic.TriggerLocation
    private let disposeBag = DisposeBag()
    
    public init(hostViewController: UIViewController, triggerLocation: WikiStatistic.TriggerLocation) {
        self.hostViewController = hostViewController
        self.triggerLocation = triggerLocation
    }
    
    // 选择文件
    public func selectFileWithPicker(allowInSpace: Bool) {
        uploadWithPicker(allowInSpace: allowInSpace, isImage: false)
    }

    public func selectImagesWithPicker(allowInSpace: Bool) {
        uploadWithPicker(allowInSpace: allowInSpace, isImage: true)
    }

    private func uploadWithPicker(allowInSpace: Bool, isImage: Bool) {
        guard let hostVC = hostViewController else { return }
        let tracker = WorkspacePickerTracker(actionType: .uploadTo, triggerLocation: triggerLocation)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_CreateIn_Header_Mob,
                                           action: .createWiki,
                                           entrances: allowInSpace ? .wikiAndSpace : .wikiOnly,
                                           ownerTypeChecker: nil,
                                           tracker: tracker) { [weak self] location, picker in
            guard let self = self else { return }
            switch location {
            case let .folder(location):
                guard location.canCreateSubNode else {
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantNew_Tooltip,
                                        on: picker.view.window ?? picker.view)
                    return
                }
                self.confirmUploadToSpace(folderToken: location.folderToken, isImage: isImage, picker: picker)
            case let .wikiNode(location):
                self.confirmUploadToWiki(wikiToken: location.wikiToken,
                                         spaceID: location.spaceID,
                                         isRootNode: location.isMainRoot,
                                         isImage: isImage,
                                         picker: picker)
            }
        }
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)
        Navigator.shared.present(picker, from: hostVC)
    }

    private func confirmUploadToWiki(wikiToken: String, spaceID: String, isRootNode: Bool, isImage: Bool, picker: UIViewController) {
        WikiStatistic.clickFileLocationSelect(targetSpaceId: spaceID,
                                              fileId: "",
                                              fileType: DocsType.file.name,
                                              filePageToken: "",
                                              viewTitle: .uploadTo,
                                              originSpaceId: "none",
                                              originWikiToken: "none",
                                              isShortcut: false,
                                              triggerLocation: triggerLocation,
                                              targetModule: .wiki,
                                              targetFolderType: nil)
        // 校验上传权限
        checkUploadPermission(wikiToken: wikiToken, spaceId: spaceID, isRootNode: isRootNode, source: picker) {
            guard let driveRouter = DocsContainer.shared.resolve(DriveRouterBase.self)?.type() else {
                spaceAssertionFailure("resolve drive router failed in wiki upload")
                return
            }
            if isImage {
                driveRouter.showAssetPickerViewController(sourceViewController: picker,
                                                          mountToken: wikiToken,
                                                          mountPoint: WikiConstants.wikiMountPoint,
                                                          scene: .wiki,
                                                          completion: { finish in
                    // did select file and upload
                    if finish {
                        picker.presentingViewController?.dismiss(animated: true, completion: nil)
                        DocsLogger.info("did upload")
                    }
                })
            } else {
                driveRouter.showDocumentPickerViewController(sourceViewController: picker,
                                                             mountToken: wikiToken,
                                                             mountPoint: WikiConstants.wikiMountPoint,
                                                             scene: .wiki,
                                                             completion: { finish in
                    // did select file and upload
                    if finish {
                        picker.presentingViewController?.dismiss(animated: true, completion: nil)
                        DocsLogger.info("did upload")
                    }
                })
            }
        }
    }
    
    private func checkUploadPermission(wikiToken: String, spaceId: String, isRootNode: Bool, source: UIViewController, completion: @escaping (() -> Void)) {
        let toastDisplayView: UIView = source.view.window ?? source.view
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Wiki_Upload_CheckingPermission,
                            on: toastDisplayView,
                            disableUserInteraction: true)
        if isRootNode {
            // Wiki 根节点权限需要用 perm/space 校验
            WikiNetworkManager.shared.getSpacePermission(spaceId: spaceId)
                .map(\.canEditFirstLevel)
                .observeOn(MainScheduler.instance)
                .subscribe { haveCreatePermission in
                    showToast(haveCreatePermission: haveCreatePermission)
                } onError: { error in
                    showToast(error: error)
                }
                .disposed(by: disposeBag)
        } else {
            WikiNetworkManager.shared.getNodePermission(spaceId: spaceId, wikiToken: wikiToken)
                .map(\.canCreate)
                .observeOn(MainScheduler.instance)
                .subscribe { haveCreatePermission in
                    showToast(haveCreatePermission: haveCreatePermission)
                } onError: { error in
                    showToast(error: error)
                }
                .disposed(by: disposeBag)
        }
        
        func showToast(haveCreatePermission: Bool) {
            UDToast.removeToast(on: toastDisplayView)
            if haveCreatePermission {
                completion()
            } else {
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob, on: toastDisplayView)
            }
        }
        
        func showToast(error: Error) {
            DocsLogger.error("fetch permission failed when create", error: error)
            let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
            UDToast.removeToast(on: toastDisplayView)
            UDToast.showFailure(with: error.addErrorDescription, on: toastDisplayView)
        }
    }

    private func confirmUploadToSpace(folderToken: String, isImage: Bool, picker: UIViewController) {
        guard let driveRouter = DocsContainer.shared.resolve(DriveRouterBase.self)?.type() else {
            spaceAssertionFailure("resolve drive router failed in wiki upload")
            return
        }
        if isImage {
            driveRouter.showAssetPickerViewController(sourceViewController: picker,
                                                      mountToken: folderToken,
                                                      mountPoint: DriveConstants.driveMountPoint,
                                                      scene: .unknown,
                                                      completion: { finish in
                // did select file and upload
                if finish {
                    picker.dismiss(animated: true, completion: nil)
                    DocsLogger.info("did upload")
                }
            })
        } else {
            driveRouter.showDocumentPickerViewController(sourceViewController: picker,
                                                         mountToken: folderToken,
                                                         mountPoint: DriveConstants.driveMountPoint,
                                                         scene: .unknown,
                                                         completion: { finish in
                // did select file and upload
                if finish {
                    picker.dismiss(animated: true, completion: nil)
                    DocsLogger.info("did upload")
                }
            })
        }
    }

    // MARK: - For Non Wiki HomePage Scene
    public func selectImages(wikiToken: String, completion: @escaping () -> Void) {
        guard let hostVC = hostViewController else { return }
        DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
            .showAssetPickerViewController(sourceViewController: hostVC,
                                           mountToken: wikiToken,
                                           mountPoint: WikiConstants.wikiMountPoint,
                                           scene: .wiki,
                                           completion: { [weak hostVC] _ in
                                            completion()
                                            DocsLogger.info("did upload")
        })
    }

    public func selectFile(wikiToken: String, completion: @escaping  () -> Void) {
        guard let hostVC = hostViewController else { return }
        DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
            .showDocumentPickerViewController(sourceViewController: hostVC,
                                              mountToken: wikiToken,
                                              mountPoint: WikiConstants.wikiMountPoint,
                                              scene: .wiki,
                                              completion: { [weak hostVC] _ in
                                                // did select file and upload
                                                DocsLogger.info("did upload")
                                                completion()
                                              })
    }
}
