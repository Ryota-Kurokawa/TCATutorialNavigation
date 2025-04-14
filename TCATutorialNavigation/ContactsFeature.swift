//
//  ContactsFeature.swift
//  TCATutorialNavigation
//
//  Created by ryota1582 on 2025/04/14.
//

import ComposableArchitecture
import SwiftUI
import Foundation

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
//　DeleteButtonが不要になったため削除
//        case deleteButtonTapped(id: Contact.ID)
        case destination(PresentationAction<Destination.Action>)
        case path(StackActionOf<ContactDetailFeature>)
        @CasePathable
        enum Alert: Equatable {
            case confirmDeletion(id: Contact.ID)
        }
    }
    @Dependency(\.uuid) var uuid
    var body: some ReducerOf<Self> {

        // 以下のSwitch文が正しく構成されていないため起こる
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                // .addContactが何かわかっていないのでContactsFeature.Destination.State.addContactと記載
                // state.destination = .addContact(
                state.destination = ContactsFeature.Destination.State.addContact(
                    AddContactFeature.State(contact: Contact(id: self.uuid(), name: ""))
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

// DeleteButtonが不要になったためこちらも削除
//            case let .deleteButtonTapped(id: id):
//                // deleteConfirmationではなくconfirmDeletion
//                // state.destination = .alert(.deleteConfirmation(id: id))
//                state.destination = .alert(.confirmDeletion(id: id))
//                return .none

            case let .path(.element(id: id, action: .delegate(.confirmDeletion))):
                guard let detailState = state.path[id: id]
                else { return .none }
                state.contacts.remove(id: detailState.contact.id)
                return .none

            case .path:
                return .none
            }
        }
        // クロージャーは不要なので削除する
        // .ifLet(\.$destination, action: \.destination) {
        //   Destination()
        // }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path) {
            ContactDetailFeature()
        }
    }
}

// 58行目で以下のエラーが発生するためこれを記載
// Cannot call value of non-function type 'AlertState<ContactDetailFeature.Action.Alert>'
//
//extension AlertState where Action == ContactsFeature.Action.Alert {
//  static func confirmDeletion(id: Contact.ID) -> Self {
//    Self {
//      TextState("Are you sure?")
//    } actions: {
//      ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
//        TextState("Delete")
//      }
//    }
//  }
//}


extension ContactsFeature {
    @Reducer
    enum Destination {
        case addContact(AddContactFeature)
        case alert(AlertState<ContactsFeature.Action.Alert>)
    }
}

extension ContactsFeature.Destination.State: Equatable {}

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
                            // NavigationLinkしか反応しないのでButtonは不要なのでは？
                            // Button {
                            //    store.send(.deleteButtonTapped(id: contact.id))
                            //} label: {
                            //    Image(systemName: "trash")
                            //        .foregroundColor(.red)
                            //}
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
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

