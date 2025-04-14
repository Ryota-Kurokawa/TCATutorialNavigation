//
//  ContactsFeature.swift
//  TCATutorialNavigation
//
//  Created by ryota1582 on 2025/04/14.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct ContactsFeature {
  @ObservableState
  struct State: Equatable {
    var contacts: IdentifiedArrayOf<Contact> = []
    @Presents var destination: Destination.State?
    var path = StackState<ContactDetailFeature.State>()
  }
  enum Action {
    case addButtonTapped
    case deleteButtonTapped(id: Contact.ID)
    case destination(PresentationAction<Destination.Action>)
    case path(StackActionOf<ContactDetailFeature>)
    @CasePathable
    enum Alert: Equatable {
      case confirmDeletion(id: Contact.ID)
    }
  }
  @Dependency(\.uuid) var uuid
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.destination = .addContact(
          AddContactFeature.State(
            contact: Contact(id: self.uuid(), name: "")
          )
        )
        return .none

      case let .destination(.presented(.addContact(.delegate(.saveContact(contact))))):
        state.contacts.append(contact)
        return .none

      case let .destination(.presented(.alert(.confirmDeletion(id: id)))):
        state.contacts.remove(id: id)
        return .none

      case .destination:
        return .none

      case let .deleteButtonTapped(id: id):
        state.destination = .alert(.deleteConfirmation(id: id))
        return .none

      case let .path(.element(id: id, action: .delegate(.confirmDeletion))):
        guard let detailState = state.path[id: id]
        else { return .none }
        state.contacts.remove(id: detailState.contact.id)
        return .none

      case .path:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
    .forEach(\.path, action: \.path) {
      ContactDetailFeature()
    }
  }
}

struct ContactsView: View {
  @Bindable var store: StoreOf<ContactsFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      List {
        ForEach(store.contacts) { contact in
          NavigationLink(state: ContactDetailFeature.State(contact: contact)) {
            HStack {
              Text(contact.name)
              Spacer()
              Button {
                store.send(.deleteButtonTapped(id: contact.id))
              } label: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
            }
          }
          .buttonStyle(.borderless)
        }
      }
      .navigationTitle("Contacts")
      .toolbar {
        ToolbarItem {
          Button {
            store.send(.addButtonTapped)
          } label: {
            Image(systemName: "plus")
          }
        }
      }
    } destination: { store in
      ContactDetailView(store: store)
    }
    .sheet(
      item: $store.scope(state: \.destination?.addContact, action: \.destination.addContact)
    ) { addContactStore in
      NavigationStack {
        AddContactView(store: addContactStore)
      }
    }
    .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
  }
}

