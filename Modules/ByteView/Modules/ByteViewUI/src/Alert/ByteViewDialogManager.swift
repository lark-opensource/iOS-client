//
//  ByteViewDialogManager.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/20.
//

import Foundation
import ByteViewCommon

public final class ByteViewDialogManager {

    public static let shared = ByteViewDialogManager()

    @RwAtomic
    var showingIds: Set<ByteViewDialogIdentifier> = []
    var autoDismissAlerts: [WeakRef<ByteViewDialog>] = []
    var showingAlerts: [WeakRef<ByteViewDialog>] = []

    /// dismiss所有needAutoDismiss的alert
    public func triggerAutoDismiss() {
        Util.runInMainThread {
            self.autoDismissAlerts.forEach { (ref) in
                ref.ref?.dismiss()
            }
            self.autoDismissAlerts = []
        }
    }

    public func dismissAllAlert() {
        Util.runInMainThread {
            self.showingAlerts.forEach {
                $0.ref?.dismiss()
            }
        }
    }

    public func dismiss(ids: Set<ByteViewDialogIdentifier>) {
        Util.runInMainThread {
            self.showingAlerts.forEach { ref in
                if let alert = ref.ref, let id = alert.showConfig.id, ids.contains(id) {
                    alert.dismiss()
                }
            }
        }
    }

    public func isShowing(_ id: ByteViewDialogIdentifier) -> Bool {
        showingIds.contains(id)
    }
}
