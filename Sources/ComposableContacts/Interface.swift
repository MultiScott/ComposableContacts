//
//  Interface.swift
//  MultiOnBrowser
//
//  Created by Scott Hoge on 12/3/24.
//

///Per Apple Documentation:
///A CNContact object stores an immutable copy of a contact’s information, so you cannot change the information in this object directly. Contact objects are thread-safe, so you may access them from any thread of your app.
@preconcurrency import Contacts
import Dependencies
import DependenciesMacros


@DependencyClient
public struct ContactsClient: Sendable {
    
    //MARK: Authorization
    public var checkAuthorization: @Sendable () async throws -> CNAuthorizationStatus = { .authorized }
    public var requestAuthorization: @Sendable () async throws -> CNAuthorizationStatus = { .authorized }
    
    //MARK: Config
    public var configureContactActor: @Sendable (ComposableContactConfig) async throws -> Void = {_ in }
    
    //MARK: Contact Retrieval
    public var getAllContacts: @Sendable ( Set<ComposableContactKey>) async throws -> [CNContact] = { _ in [] }
    public var getContact: @Sendable ( ContactWithIdentifierRequest) async throws -> CNContact = { _ in .johnDoe }
    
    public var getContactsInContainer: @Sendable (ContactsInContainerRequest) async throws -> [CNContact] = { _ in [] }
    public var getContactsInGroup: @Sendable (ContactsInGroupRequest) async throws -> [CNContact] = { _ in [] }
    
    public var getContactsMatchingEmail: @Sendable (ContactsMatchingEmailRequest) async throws -> [CNContact] = { _ in [] }
    public var getContactsMatchingName: @Sendable (ContactsMatchingNameRequest) async throws -> [CNContact] = { _ in [] }
    public var getContactsMatchingPhoneNumber: @Sendable (ContactsMatchingPhoneNumberRequest) async throws -> [CNContact] = { _ in [] }
    
    public var getContactsWithIdentifiers: @Sendable (ContactsWithIdentifiersRequest) async throws -> [CNContact] = { _ in [] }
    
    
    //MARK: Contact Writes
    public var createNewContact: @Sendable (CNContact) async throws -> Void = {_ in  }
    public var createNewContacts: @Sendable (UncheckedSendable<Set<CNContact>>) async throws -> Void = {_ in  }
    public var modifyContact: @Sendable (CNContact) async throws -> Void = {_ in  }
    public var modifyContacts: @Sendable (UncheckedSendable<Set<CNContact>>) async throws -> Void = {_ in  }
    
    //MARK: Container Retrieval
    public var getAllContainers: @Sendable () async throws -> [CNContainer] = { .init() }
    public var getContainerForContactID: @Sendable (String) async throws -> CNContainer = { _ in .init() }
    public var getContainerOfGroupWithID: @Sendable (String) async throws -> CNContainer = { _ in .init() }
    public var getContainerOfGroupsWithIDs: @Sendable ([String]) async throws -> [CNContainer] = { _ in .init() }

    //MARK: Group Retrieval
    public var getAllGroups: @Sendable () async throws -> [CNGroup] = { .init() }
    public var getAllGroupsWithIdentifiers: @Sendable ([String]) async throws -> [CNGroup] = { _ in .init() }
    public var getAllGroupsInContainerWithID: @Sendable (String) async throws -> CNGroup = { _ in .init() }

}

// MARK: DataTypes
public enum ContactError: Error {
    case failedToCreateMutableCopy
    case failedToEnumerateChangeHistory
    case failedToMapContactType
    case operationNotAllowedOnWatchOS
    case failedToFindContainerForContact(String)
    case failedToFindContainerForGroup(String)
    case failedToFindGroupForID(String)
    case unauthorized
    case noEventVisitorAssigned
    case NSContactsUsageDescriptionNotSet
}

public struct ComposableContactConfig: Sendable {
    let historyToken: Data?
    let eventVisitor: CNChangeHistoryEventVisitor
}

public struct ContactWithIdentifierRequest: Sendable {
    let identifier: String
    let keysToFetch:  Set<ComposableContactKey>
}

public struct ContactsWithIdentifiersRequest: Sendable {
    let identifiers: [String]
    let keysToFetch:  Set<ComposableContactKey>
}

public struct ContactsMatchingPhoneNumberRequest: Sendable {
    let phoneNumber: String
    let keysToFetch:  Set<ComposableContactKey>
}

public struct ContactsMatchingNameRequest: Sendable {
    let name: String
    let keysToFetch:  Set<ComposableContactKey>
}

public struct ContactsMatchingEmailRequest: Sendable {
    let email: String
    let keysToFetch:  Set<ComposableContactKey>
}

public struct ContactsInGroupRequest: Sendable {
    let groupID: String
    let keysToFetch:  Set<ComposableContactKey>
}

public struct ContactsInContainerRequest: Sendable {
    let containerID: String
    let keysToFetch:  Set<ComposableContactKey>
}
