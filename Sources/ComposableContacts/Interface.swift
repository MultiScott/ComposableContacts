//
//  Interface.swift
//  MultiOnBrowser
//
//  Created by Scott Hoge on 12/3/24.
//

///Per Apple Documentation:

@preconcurrency import Contacts
import Dependencies
import DependenciesMacros


/// A `DependencyClient` that provides an interface to Apple's Contacts API using async functions.
/// The `ContactsClient` encapsulates authorization checks, configuration, contact retrieval, and contact mutation.
///
/// **Setup**
///  - Set `NSContactsUsageDescription` in your info.plist
///  - Request authorization
///  - Then set the configuration on the actor
///
///  If the configuration is not set then no events will be relayed to the `CNChangeHistoryEventVisitor`
///
/// `ContactsClient` uses [CNContact](https://developer.apple.com/documentation/contacts/cncontact) as input's and outputs for various pieces of functionality.
///
///  Per Apple Documentation:
///
/// A `CNContact` object stores an immutable copy of a contact’s information, so you cannot change the information in this object directly. Contact objects are thread-safe, so you may access them from any thread of your app.
@DependencyClient
public struct ContactsClient: Sendable {
    
    //MARK: Authorization
    
    /// Retrieves the current authorization status for accessing the user's contacts.
    /// - Returns: The current authorization status (`CNAuthorizationStatus`) indicating whether the client is authorized, restricted, denied, or not determined.
    public var checkAuthorization: @Sendable () async throws -> CNAuthorizationStatus = { .authorized }
    /// Requests authorization from the user to access their contacts.
    /// If the user has not yet granted or denied permission, this will prompt the user.
    /// - Returns: The resulting authorization status after the request is made.
    public var requestAuthorization: @Sendable () async throws -> CNAuthorizationStatus = { .authorized }
    
    //MARK: Config
    
    /// Configures the contact actor with a given `ComposableContactConfig`.
    /// This is used to set up event visitors or history tokens for change-tracking in the contact store.
    /// - Parameter config: A `ComposableContactConfig` containing a history token and a change history event visitor.
    /// - Throws: May throw if configuration fails.
    public var configureContactActor: @Sendable (ComposableContactConfig) async throws -> Void = {_ in }
    
    //MARK: Contact Retrieval
    
    /// Retrieves all contacts with the properties outined  requested in a set of keys to fetch.
    /// - Parameter keysToFetch: A set of `ComposableContactKey` indicating which contact properties should be fetched.
    /// - Returns: An array of `CNContact` matching the requested keys.
    public var getAllContacts: @Sendable ( Set<ComposableContactKey>) async throws -> [CNContact] = { _ in [] }
    
    /// Retrieves a single contact by its identifier.
    /// - Parameter request: A `ContactWithIdentifierRequest` specifying the contact's identifier and keys to fetch.
    /// - Returns: The `CNContact` object associated with the provided identifier.
    public var getContact: @Sendable ( ContactWithIdentifierRequest) async throws -> CNContact = { _ in .johnDoe }
    
    /// Retrieves all contacts contained in the specified container.
    /// - Parameter request: A `ContactsInContainerRequest` specifying the container ID and keys to fetch.
    /// - Returns: An array of `CNContact` objects in the specified container.
    public var getContactsInContainer: @Sendable (ContactsInContainerRequest) async throws -> [CNContact] = { _ in [] }
    
    /// Retrieves all contacts belonging to a specified group.
    /// - Parameter request: A `ContactsInGroupRequest` specifying the group ID and keys to fetch.
    /// - Returns: An array of `CNContact` objects in the specified group.
    public var getContactsInGroup: @Sendable (ContactsInGroupRequest) async throws -> [CNContact] = { _ in [] }
    
    /// Retrieves all contacts matching a provided email address.
    /// - Parameter request: A `ContactsMatchingEmailRequest` specifying the email to search for and keys to fetch.
    /// - Returns: An array of `CNContact` objects whose emails match the provided email.
    public var getContactsMatchingEmail: @Sendable (ContactsMatchingEmailRequest) async throws -> [CNContact] = { _ in [] }
    
    /// Retrieves all contacts matching a provided name.
    /// - Parameter request: A `ContactsMatchingNameRequest` specifying the name substring or full name and keys to fetch.
    /// - Returns: An array of `CNContact` objects that match the specified name criteria.
    public var getContactsMatchingName: @Sendable (ContactsMatchingNameRequest) async throws -> [CNContact] = { _ in [] }
    
    /// Retrieves all contacts matching a provided phone number.
    /// - Parameter request: A `ContactsMatchingPhoneNumberRequest` specifying the phone number and keys to fetch.
    /// - Returns: An array of `CNContact` objects that match the specified phone number.
    public var getContactsMatchingPhoneNumber: @Sendable (ContactsMatchingPhoneNumberRequest) async throws -> [CNContact] = { _ in [] }
    
    /// Retrieves all contacts whose identifiers match the given list.
    /// - Parameter request: A `ContactsWithIdentifiersRequest` containing a list of contact identifiers and keys to fetch.
    /// - Returns: An array of `CNContact` objects corresponding to the given identifiers.
    public var getContactsWithIdentifiers: @Sendable (ContactsWithIdentifiersRequest) async throws -> [CNContact] = { _ in [] }
    
    
    //MARK: Contact Writes
    
    /// Creates a new contact and adds it to the contact store.
    /// - Parameter contact: A `CNContact` object representing the contact to be created.
    public var createNewContact: @Sendable (CNContact) async throws -> Void = {_ in  }
    
    /// Batches creation of multiple new contacts and adds them to the contact store.
    /// - Parameter contacts: A set of `CNContact` objects (wrapped in `UncheckedSendable`) to be created.
    public var createNewContacts: @Sendable (UncheckedSendable<Set<CNContact>>) async throws -> Void = {_ in  }
    
    /// Modifies an existing contact in the contact store.
    /// - Parameter contact: A `CNContact` object with updated fields.
    public var modifyContact: @Sendable (CNContact) async throws -> Void = {_ in  }
    
    /// Batches modification of multiple existing contacts in the contact store.
    /// - Parameter contacts: A set of `CNContact` objects (wrapped in `UncheckedSendable`) to be updated.
    public var modifyContacts: @Sendable (UncheckedSendable<Set<CNContact>>) async throws -> Void = {_ in  }
    
    //MARK: Container Retrieval
    
    /// Retrieves all contact containers from the contact store.
    /// - Returns: An array of [CNContainer](https://developer.apple.com/documentation/contacts/cncontainer) objects.
    public var getAllContainers: @Sendable () async throws -> [CNContainer] = { .init() }
    
    /// Retrieves the container that a specific contact belongs to, given the contact's identifier.
    /// - Parameter contactID: The identifier of the contact.
    /// - Returns: The `CNContainer` that the contact belongs to.
    public var getContainerForContactID: @Sendable (String) async throws -> CNContainer = { _ in .init() }
    
    /// Retrieves the container that a specific group belongs to, given the group's identifier.
    /// - Parameter groupID: The identifier of the group.
    /// - Returns: The `CNContainer` that the group belongs to.
    public var getContainerOfGroupWithID: @Sendable (String) async throws -> CNContainer = { _ in .init() }
    
    /// Retrieves the containers for a list of group identifiers.
    /// - Parameter groupIDs: An array of group identifiers.
    /// - Returns: An array of `CNContainer` objects corresponding to the given group IDs.
    public var getContainerOfGroupsWithIDs: @Sendable ([String]) async throws -> [CNContainer] = { _ in .init() }

    //MARK: Group Retrieval
    
    /// Retrieves all groups from the contact store.
    /// - Returns: An array of `CNGroup` objects.
    public var getAllGroups: @Sendable () async throws -> [CNGroup] = { .init() }
    
    /// Retrieves all groups with the specified identifiers.
    /// - Parameter groupIDs: An array of group identifiers.
    /// - Returns: An array of `CNGroup` objects matching the given identifiers.
    public var getAllGroupsWithIdentifiers: @Sendable ([String]) async throws -> [CNGroup] = { _ in .init() }
    
    /// Retrieves all groups within a specific container.
    /// - Parameter containerID: The identifier of the container.
    /// - Returns: A `CNGroup` object for groups found in the specified container.
    public var getAllGroupsInContainerWithID: @Sendable (String) async throws -> CNGroup = { _ in .init() }

}

// MARK: DataTypes
/// An enumeration of errors that may arise when interacting with the `ContactClient`.
public enum ContactError: Error {
    /// Indicates a failed attempt to create a mutable copy of a `CNContact`.
    case failedToCreateMutableCopy
    /// Indicates a failure to enumerate change history from the contact store.
    case failedToEnumerateChangeHistory
    /// Indicates a failure to map the `CNContactType` (e.g., unknown or unsupported type).
    case failedToMapContactType
    /// Indicates an attempted operation that is not allowed on watchOS devices.
    case operationNotAllowedOnWatchOS
    /// Indicates that no container could be found for a given contact.
    case failedToFindContainerForContact(String)
    /// Indicates that no container could be found for a given group.
    case failedToFindContainerForGroup(String)
    /// Indicates that no group could be found for the given group ID.
    case failedToFindGroupForID(String)
    /// Indicates that the user is not authorized to access contacts.
    case unauthorized
    /// Indicates that no `CNChangeHistoryEventVisitor` was assigned when required.
    case noEventVisitorAssigned
    /// Indicates that the `NSContactsUsageDescription` key is not set in the Info.plist.
    case NSContactsUsageDescriptionNotSet
}
/// Configuration options for the contact actor.
/// Contains optional change history tokens and a `CNChangeHistoryEventVisitor` to track contact store changes.
public struct ComposableContactConfig: Sendable {
    /// A token representing the state of the contact store at a particular point in time.
    let historyToken: Data?
    /// An event visitor for enumerating and responding to change history events in the contact store.
    let eventVisitor: CNChangeHistoryEventVisitor
}

/// A request structure specifying a contact to retrieve by its identifier along with the keys to fetch.
public struct ContactWithIdentifierRequest: Sendable {
    /// The unique identifier of the contact to retrieve.
    let identifier: String
    /// A set of `ComposableContactKey` values indicating which contact properties to fetch.
    let keysToFetch: Set<ComposableContactKey>
}

/// A request structure for retrieving multiple contacts by their identifiers and specifying keys to fetch.
public struct ContactsWithIdentifiersRequest: Sendable {
    /// A list of contact identifiers.
    let identifiers: [String]
    /// A set of `ComposableContactKey` values indicating which contact properties to fetch.
    let keysToFetch: Set<ComposableContactKey>
}

/// A request structure for retrieving contacts by a phone number.
public struct ContactsMatchingPhoneNumberRequest: Sendable {
    /// The phone number to match (exact or partial).
    let phoneNumber: String
    /// A set of `ComposableContactKey` values indicating which contact properties to fetch.
    let keysToFetch: Set<ComposableContactKey>
}

/// A request structure for retrieving contacts by a name substring or full name.
public struct ContactsMatchingNameRequest: Sendable {
    /// The name or substring to match.
    let name: String
    /// A set of `ComposableContactKey` values indicating which contact properties to fetch.
    let keysToFetch: Set<ComposableContactKey>
}

/// A request structure for retrieving contacts by an email address.
public struct ContactsMatchingEmailRequest: Sendable {
    /// The email address to match.
    let email: String
    /// A set of `ComposableContactKey` values indicating which contact properties to fetch.
    let keysToFetch: Set<ComposableContactKey>
}

/// A request structure for retrieving contacts that belong to a specific group.
public struct ContactsInGroupRequest: Sendable {
    /// The identifier of the group whose contacts should be retrieved.
    let groupID: String
    /// A set of `ComposableContactKey` values indicating which contact properties to fetch.
    let keysToFetch: Set<ComposableContactKey>
}

/// A request structure for retrieving contacts in a specific container.
public struct ContactsInContainerRequest: Sendable {
    /// The identifier of the container whose contacts should be retrieved.
    let containerID: String
    /// A set of `ComposableContactKey` values indicating which contact properties to fetch.
    let keysToFetch: Set<ComposableContactKey>
}
