//
//  TCATutorialNavigationApp.swift
//  TCATutorialNavigation
//
//  Created by ryota1582 on 2025/04/14.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCATutorialNavigationApp: App {
    static let store = Store(initialState: ContactsFeature.State()) {
        ContactsFeature()
    }

    var body: some Scene {
        WindowGroup {
            ContactsView(store: TCATutorialNavigationApp.store)
        }
    }
}
