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
    public var checkAccess: @Sendable () async throws -> CNAuthorizationStatus = { .authorized }
    public var requestAccess: @Sendable () async throws -> CNAuthorizationStatus = { .authorized }
    public var getDataForContacts: @Sendable ([ComposableContactKey]) async throws -> [CNContact] = { _ in [] }
    public var getDataForContact: @Sendable ([ComposableContactKey]) async throws -> CNContact = { _ in  .johnDoe}
    public var getKeyForContact: @Sendable () async throws -> String = {""}
    public var initSharedComposableContacts:  @Sendable () async throws -> String = {""}
}

// MARK: DataTypes
public enum ContactError: Error {
    case failedToCreateMutableCopy
    case failedToEnumerateChangeHistory
    case failedToMapContactType
    case operationNotAllowed
    case failedToFindContainerForContact(String)
    case failedToFindContainerForGroup(String)
    case failedToFindGroupForID(String)
    case unauthorized
}

public struct ComposableContactClientConfig: Sendable {
    let historyToken: Data?
    let eventVisitor: CNChangeHistoryEventVisitor
}
