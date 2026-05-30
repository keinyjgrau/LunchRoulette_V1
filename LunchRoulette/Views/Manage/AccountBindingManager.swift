//
//  AccountBindingManager.swift
//  LunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-05-29.
//


import SwiftUI
import GameKit
import UIKit
import Combine

@MainActor
final class AccountBindingManager: ObservableObject {
    @Published var isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
    @Published var gameCenterDisplayName: String? = GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local.displayName : nil
    @Published var bindMessage: String? = nil
    @Published var isBusy = false

    func refreshState() {
        isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
        gameCenterDisplayName = GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local.displayName : nil
    }

    func bindGameCenter() {
        isBusy = true
        bindMessage = nil

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }

            Task { @MainActor in
                if let viewController {
                    self.present(viewController: viewController)
                    return
                }

                self.isBusy = false

                if let error {
                    self.bindMessage = error.localizedDescription
                    self.refreshState()
                    return
                }

                self.refreshState()

                if self.isGameCenterAuthenticated {
                    self.bindMessage = "Game Center connected."
                } else {
                    self.bindMessage = "Game Center is not connected."
                }
            }
        }
    }

    func facebookPlaceholder() {
        bindMessage = "Facebook binding can be added later."
    }

    private func present(viewController: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            isBusy = false
            bindMessage = "Could not present the Game Center sign-in screen."
            return
        }

        let presenter = topMostViewController(from: root)
        presenter.present(viewController, animated: true)
    }

    private func topMostViewController(from root: UIViewController) -> UIViewController {
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
