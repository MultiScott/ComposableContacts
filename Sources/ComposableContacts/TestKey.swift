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
        requestAccess: { .authorized },
        getDataForContacts: {_ in []},
        getDataForContact: {_ in .johnDoe },
        getKeyForContact: {""}
    )
}
