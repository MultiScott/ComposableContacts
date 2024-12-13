//
//  ContactTestKey.swift
//  MultiOnBrowser
//
//  Created by Scott Hoge on 12/3/24.
//

import Dependencies

public extension DependencyValues {
    var contactsClient: ContactsClient {
        get { self[ContactsClient.self] }
        set { self[ContactsClient.self] = newValue }
    }
}

extension ContactsClient: TestDependencyKey {
    public static let previewValue = Self.noop
    public static let testValue = Self()
}

// MARK: Preview Implementation
public extension ContactsClient {
    static let noop = Self(
        checkAuthorization: { .authorized  },
        requestAuthorization: { .authorized },
        configureContactActor: {_ in .finished},
        getAllContacts: {_ in [.johnDoe, .janeDoe]},
        getContact: {_ in .johnDoe},
        getContactsInContainer: { _ in [] },
        getContactsInGroup: { _ in [] },
        getContactsMatchingEmail: { _ in [] },
        getContactsMatchingName: { _ in [] },
        getContactsMatchingPhoneNumber: { _ in [] },
        getContactsWithIdentifiers: { _ in [] },
        createNewContact: { _ in },
        createNewContacts: { _ in },
        modifyContact: { _ in },
        modifyContacts: { _ in },
        getAllContainers: { [] },
        getContainerForContactID: { _ in .init() },
        getContainerOfGroupWithID: { _ in .init() },
        getContainerOfGroupsWithIDs: { _ in [] },
        getAllGroups: { [] },
        getAllGroupsWithIdentifiers: { _ in [] },
        getAllGroupsInContainerWithID: { _ in .init() }
    )
}
