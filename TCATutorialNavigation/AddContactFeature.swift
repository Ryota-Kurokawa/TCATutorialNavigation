//
//  AddContactFeature.swift
//  TCATutorialNavigation
//
//  Created by ryota1582 on 2025/04/14.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct AddContactFeature {
  @ObservableState
  struct State: Equatable {
    var contact: Contact
  }
  enum Action {
    case cancelButtonTapped
    case saveButtonTapped
    case setName(String)
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .cancelButtonTapped:
        return .none

      case .saveButtonTapped:
        return .none

      case let .setName(name):
        state.contact.name = name
        return .none
      }
    }
  }
}

struct AddContactView: View {
  @Bindable var store: StoreOf<AddContactFeature>


  var body: some View {
    Form {
      TextField("Name", text: $store.contact.name.sending(\.setName))
      Button("Save") {
        store.send(.saveButtonTapped)
      }
    }
    .toolbar {
      ToolbarItem {
        Button("Cancel") {
          store.send(.cancelButtonTapped)
        }
      }
    }
  }
}
