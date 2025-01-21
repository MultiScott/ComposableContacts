//
//  ContactLiveKey.swift
//  MultiOnBrowser
//
//  Created by Scott Hoge on 12/3/24.
//

///Per Apple Documentation:
///A CNContact object stores an immutable copy of a contact’s information, so you cannot change the information in this object directly. Contact objects are thread-safe, so you may access them from any thread of your app.
@preconcurrency import Contacts
import CNContactStoreWrapper
import Dependencies
import Combine

// MARK: Live
@available(iOSApplicationExtension, unavailable)
extension ContactsClient: DependencyKey {
    // Map Interface to live methods
    public static var liveValue: Self {
        return Self(
            checkAuthorization: { return await ContactActor.shared.checkAuthorization() },
            requestAuthorization: {return try await ContactActor.shared.requestAccess()},
            configureContactActor: {config in try await ContactActor.shared.configureActor(with: config)},
            getAllContacts: {request in try await ContactActor.shared.getAllContacts(with: request.keysToFetch, in: request.order)},
            getContact: {request in try await ContactActor.shared.getContact(with: request.identifier, and: request.keysToFetch)},
            getContactsInContainer: {request in try await ContactActor.shared.getContacts(inContainer: request.containerID, and: request.keysToFetch)},
            getContactsInGroup: {request in try await ContactActor.shared.getContacts(inGroup: request.groupID, and: request.keysToFetch)},
            getContactsMatchingEmail: {request in try await ContactActor.shared.getContacts(matchingEmailAddress: request.email, and: request.keysToFetch)},
            getContactsMatchingName: {request in try await ContactActor.shared.getContacts(matchingName: request.name, and: request.keysToFetch)},
            getContactsMatchingPhoneNumber: {request in try await ContactActor.shared.getContacts(matchingphoneNumber: request.phoneNumber, and: request.keysToFetch)},
            getContactsWithIdentifiers: {request in try await ContactActor.shared.getContacts(withIdentifiers: request.identifiers, and: request.keysToFetch)},
            createNewContact: {contact in try await ContactActor.shared.createNewContact(contact: contact) },
            createNewContacts: {contacts in try await ContactActor.shared.createNewContacts(contacts: contacts)},
            modifyContact: {contact in try await ContactActor.shared.modifyContact(contact: contact) },
            modifyContacts: {contacts in try await ContactActor.shared.modifyContacts(contacts: contacts) },
            getAllContainers: { try await ContactActor.shared.getAllContainers() },
            getContainerForContactID: {contactID in try await ContactActor.shared.getContainerForContact(with: contactID) },
            getContainerOfGroupWithID: {ID in try await ContactActor.shared.getContainerOfGroup(with: ID) },
            getContainerOfGroupsWithIDs: {IDs in try await ContactActor.shared.getContainerForGoups(with: IDs) },
            getAllGroups: { try await ContactActor.shared.getAllGroups() },
            getAllGroupsWithIdentifiers: {IDs in try await ContactActor.shared.getGroups(with: IDs) },
            getAllGroupsInContainerWithID: {ID in try await ContactActor.shared.getGroupsInContainer(with: ID) }
        )
    }
}

/// A global actor responsible for executing contact-related operations on a `CNContactStore`.
/// The `ContactActor` manages access authorization, contact retrieval, and modifications within
/// Apple’s Contacts framework. It also supports change-tracking through the use of history tokens
/// and event visitors, and can observe `CNContactStore` notifications to automatically update state.
///
/// **Key Capabilities:**
/// - Checking and requesting contact store authorization.
/// - Configuring contact event visitors for change-tracking.
/// - Retrieving individual contacts, all contacts, or subsets based on various criteria (name, email, phone number, group/container membership).
/// - Creating and modifying contacts within the user’s address book.
/// - Retrieving containers and groups for organizing contacts.
/// - Observing changes in the contact store and enumerating change history.
///
/// - Note: All of the methods are declared `fileprivate`. This grants access to the live implmentation of `ContactsClient` but not to code running outside of the file.
@globalActor
public final actor ContactActor {
    public static let shared = ContactActor()
    
    private var cancellables: Set<AnyCancellable> = []
    private let contactStore = CNContactStore()
    private var currentHistoryToken: Data?
    private var eventVisitor : CNChangeHistoryEventVisitor?
    private var continuation: AsyncStream<Data?>.Continuation?
    private var dataStream: AsyncStream<Data?>?
    
    init() {
        // Initialize the async stream
        var tokenCont: AsyncStream<Data?>.Continuation!
        dataStream = AsyncStream<Data?> { continuation in
            tokenCont = continuation
        }
        continuation = tokenCont
    }
    
    deinit {
        continuation?.finish()
    }
    
    //MARK: Authorization
    
    /// Retrieves the current authorization status for accessing the user's contacts.
    /// - Returns: The current authorization status (`CNAuthorizationStatus`) indicating whether the client is authorized, restricted, denied, or not determined.
    fileprivate func checkAuthorization() -> CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }
    
    /// Requests the user’s permission to access contacts, if not already determined.
    ///
    /// - Returns: The updated `CNAuthorizationStatus` after requesting access.
    /// - Throws: `ContactError.NSContactsUsageDescriptionNotSet` if the `NSContactsUsageDescription` key is missing in the Info.plist.
    fileprivate func requestAccess() async throws -> CNAuthorizationStatus {
        try guardContactUsageDescription()
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard currentStatus == .notDetermined else {
            return currentStatus
        }
        let _ = try await contactStore.requestAccess(for: .contacts)
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    
    //MARK: Config
    
    /// Configures the contact actor with a given `ComposableContactConfig`, setting up event visitors and history tokens.
    ///
    /// - Parameter config: A `ComposableContactConfig` containing a history token and a change history event visitor.
    fileprivate func configureActor(with config: ComposableContactConfig) throws -> AsyncStream<Data?> {
        currentHistoryToken = config.historyToken
        eventVisitor = config.eventVisitor
        observeNotifications()
        try fetchChanges()
        return try getTokenStream()
    }
    
    ///Returns the `AsyncStream<Data?>` for the historyToken
    fileprivate func getTokenStream() throws -> AsyncStream<Data?> {
        guard let dataStream else {
            throw ContactError.noDataStreamSet
        }
        return dataStream
    }
    
    //MARK: Contact Retrieval
    
    /// Retrieves a single contact by identifier.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the contact to retrieve.
    ///   - keysToFetch: A set of `ComposableContactKey` values specifying which properties to include.
    /// - Returns: The `CNContact` matching the given identifier.
    fileprivate func getContact(with id: String, and keysToFetch: Set<ComposableContactKey>) throws -> CNContact {
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let cnKeysToFetch = updatedKeys.map { $0.keyDescriptor }
        let cnContact = try contactStore.unifiedContact(withIdentifier: id, keysToFetch: cnKeysToFetch)
        return cnContact
    }
    
    /// Retrieves all contacts with specified properties.
    ///
    /// - Parameter keysToFetch: A set of `ComposableContactKey` values specifying which properties to include.
    /// - Returns: An array of `CNContact` objects for all contacts accessible to this application.
    fileprivate func getAllContacts(with keysToFetch: Set<ComposableContactKey>, in order: CNContactSortOrder) throws -> [CNContact] {
        try guardAuthorizationStatus()
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let request = CNContactFetchRequest(keysToFetch: updatedKeys.map {$0.keyDescriptor})
        request.sortOrder = order
        var contacts: [CNContact] = []
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        return contacts
    }
    
    /// Retrieves multiple contacts by their identifiers.
    ///
    /// - Parameters:
    ///   - identifiers: An array of contact identifiers to fetch.
    ///   - keysToFetch: A set of properties to include for each contact.
    /// - Returns: An array of `CNContact` objects for the specified identifiers.
    fileprivate func getContacts(withIdentifiers identifiers: [String], and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(withIdentifiers: identifiers)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    /// Retrieves contacts matching a given phone number.
    ///
    /// - Parameters:
    ///   - phoneNumber: The phone number to match.
    ///   - keysToFetch: A set of properties to include for each contact.
    /// - Returns: An array of `CNContact` objects whose phone numbers match the given string.
    fileprivate func getContacts(matchingphoneNumber phoneNumber: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let phoneNumber = CNPhoneNumber(stringValue: phoneNumber)
        let pred = CNContact.predicateForContacts(matching: phoneNumber)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    /// Retrieves contacts matching a given name.
    ///
    /// - Parameters:
    ///   - name: The substring or full name to match.
    ///   - keysToFetch: A set of properties to include for each contact.
    /// - Returns: An array of `CNContact` objects whose names match the given criteria.
    fileprivate func getContacts(matchingName name: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(matchingName: name)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    /// Retrieves contacts matching a given email address.
    ///
    /// - Parameters:
    ///   - emailAddress: The email address to match.
    ///   - keysToFetch: A set of properties to include for each contact.
    /// - Returns: An array of `CNContact` objects whose emails match the given address.
    fileprivate func getContacts(matchingEmailAddress emailAddress: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(matchingEmailAddress: emailAddress)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    /// Retrieves contacts that belong to a specific group.
    ///
    /// - Parameters:
    ///   - groupIdentifier: The identifier of the group.
    ///   - keysToFetch: A set of properties to include for each contact.
    /// - Returns: An array of `CNContact` objects in the specified group.
    fileprivate func getContacts(inGroup groupIdentifier: String, and keysToFetch:Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContactsInGroup(withIdentifier: groupIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    /// Retrieves contacts that belong to a specific container.
    ///
    /// - Parameters:
    ///   - containerIdentifier: The identifier of the container.
    ///   - keysToFetch: A set of properties to include for each contact.
    /// - Returns: An array of `CNContact` objects in the specified container.
    fileprivate func getContacts(inContainer containerIdentifier: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContactsInContainer(withIdentifier: containerIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    /// Retrieves contacts matching a given predicate.
    ///
    /// - Parameters:
    ///   - predicate: An `NSPredicate` specifying the search criteria.
    ///   - keysToFetch: A set of properties to include for each contact.
    /// - Returns: An array of `CNContact` objects matching the specified predicate.
    ///
    /// This method is used by other contact retrieval methods and inclused checking auth status.
    fileprivate func getContacts(matching predicate: NSPredicate, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        try guardAuthorizationStatus()
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let cnKeysToFetch = updatedKeys.map { $0.keyDescriptor }
        let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: cnKeysToFetch)
        return cnContacts
    }
    
    //MARK: Contact Writes
    
    /// Creates a new contact and optionally places it into a specified container.
    ///
    /// - Parameters:
    ///   - contact: The `CNContact` to be created.
    ///   - containerWithIdentifier: An optional container identifier where the contact should be placed.
    /// - Throws: `operationNotAllowedOnWatchOS` if attempted from the watch. Writes to contacts are not allowed in `WatchOS`
    fileprivate func createNewContact(contact: CNContact, to containerWithIdentifier: String? = nil) async throws {
        try guardIfWatchOS()
        try guardAuthorizationStatus()
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            throw ContactError.failedToCreateMutableCopy
        }
        let saveRequest = CNSaveRequest()
        saveRequest.add(mutableContact, toContainerWithIdentifier: containerWithIdentifier)
        try contactStore.execute(saveRequest)
    }
    
    /// Creates multiple new contacts and optionally places them into a specified container.
    ///
    /// - Parameters:
    ///   - contacts: A set of `CNContact` objects (wrapped in `UncheckedSendable`) to be created.
    ///   - containerWithIdentifier: An optional container identifier where the contacts should be placed.
    fileprivate func createNewContacts(contacts: UncheckedSendable<Set<CNContact>>, to containerWithIdentifier: String? = nil) async throws {
        try guardIfWatchOS()
        try guardAuthorizationStatus()
        let saveRequest = CNSaveRequest()
        for contact in contacts.value {
            guard let newContact = contact.mutableCopy() as? CNMutableContact else {
                throw ContactError.failedToCreateMutableCopy
            }
            saveRequest.add(newContact, toContainerWithIdentifier: containerWithIdentifier)
        }
        try contactStore.execute(saveRequest)
    }
    
    /// Modifies an existing contact.
    ///
    /// - Parameter contact: The `CNContact` object containing the updated fields.
    /// - Throws:
    fileprivate func modifyContact(contact: CNContact) async throws {
        try guardIfWatchOS()
        try guardAuthorizationStatus()
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            throw ContactError.failedToCreateMutableCopy
        }
        let keys = mutableContact.getFetchedKeys()
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)
        try contactStore.execute(saveRequest)
    }
    
    /// Modifies multiple existing contacts.
    ///
    /// - Parameter contacts: A set of `CNContact` objects (wrapped in `UncheckedSendable`) to be updated.
    fileprivate func modifyContacts(contacts: UncheckedSendable<Set<CNContact>>) async throws {
        try guardIfWatchOS()
        try guardAuthorizationStatus()
        let saveRequest = CNSaveRequest()
        for contact in contacts.value {
            guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
                throw ContactError.failedToCreateMutableCopy
            }
            saveRequest.update(mutableContact)
        }
        try contactStore.execute(saveRequest)
    }
    
    //MARK: Container Retrieval
    
    /// Retrieves containers that match a given predicate. If no predicate is provided, retrieves all accessible containers.
    ///
    /// - Parameter predicate: An optional `NSPredicate` for filtering containers.
    ///
    /// This method is used by all other container retrieval methods and inclused checking auth status.
    fileprivate func getContainers(matching predicate:  NSPredicate? = nil) throws -> [CNContainer] {
        try guardAuthorizationStatus()
        return try contactStore.containers(matching: predicate)
    }
    
    fileprivate func getAllContainers() throws -> [CNContainer] {
        return try getContainers()
    }
    
    /// Retrieves the container for a given contact.
    ///
    /// - Parameter id: The identifier of the contact.
    /// - Returns: The `CNContainer` that the contact belongs to.
    fileprivate func getContainerForContact(with id: String) async throws -> CNContainer {
        let pred = CNContainer.predicateForContainerOfContact(withIdentifier: id)
        let containers = try getContainers(matching: pred)
        guard let container = containers.first else {
            throw ContactError.failedToFindContainerForContact(id)
        }
        return container
    }
    
    /// Retrieves the container for a given group.
    ///
    /// - Parameter id: The identifier of the group.
    /// - Returns: The `CNContainer` that the group belongs to.
    fileprivate func getContainerOfGroup(with id: String) async throws -> CNContainer {
        let pred = CNContainer.predicateForContainerOfGroup(withIdentifier: id)
        let containers = try getContainers(matching: pred)
        guard let container = containers.first else {
            throw ContactError.failedToFindContainerForGroup(id)
        }
        return container
    }
    
    /// Retrieves containers for the specified list of identifiers.
    ///
    /// - Parameter identifiers: An array of container identifiers.
    fileprivate func getContainerForGoups(with identifiers: [String])async  throws -> [CNContainer] {
        let pred = CNContainer.predicateForContainers(withIdentifiers: identifiers)
        let containers = try getContainers(matching: pred)
        return containers
    }
    
    //MARK: Group Retrieval
    
    /// Retrieves groups that match a given predicate. If no predicate is provided, retrieves all accessible groups.
    ///
    /// - Parameter predicate: An optional `NSPredicate` for filtering groups.
    ///
    /// This method is used by all other group retrieval methods and inclused checking auth status.
    fileprivate func getGroups(matching predicate:  NSPredicate? = nil) throws -> [CNGroup] {
        try guardAuthorizationStatus()
        return try contactStore.groups(matching: predicate)
    }
    
    fileprivate func getAllGroups() throws -> [CNGroup] {
        return try getGroups()
    }
    
    /// Retrieves groups by their identifiers.
    ///
    /// - Parameter identifiers: An array of group identifiers.
    fileprivate func getGroups(with identifiers: [String]) async throws -> [CNGroup]{
        let pred = CNGroup.predicateForGroups(withIdentifiers: identifiers)
        return try getGroups(matching: pred)
    }
    
    /// Retrieves groups within a given container.
    ///
    /// - Parameter id: The identifier of the container.
    fileprivate func getGroupsInContainer(with id: String) async throws -> CNGroup {
        let pred = CNGroup.predicateForGroupsInContainer(withIdentifier: id)
        let groups = try getGroups(matching: pred)
        guard let group = groups.first else {
            throw ContactError.failedToFindGroupForID(id)
        }
        return group
    }
    
    /// Fetches and processes changes from the contact store using the current history token and sends to the assigned `CNChangeHistoryEventVisitor`.
    fileprivate func fetchChanges() throws {
        try guardAuthorizationStatus()
        let fetchRequest = CNChangeHistoryFetchRequest()
        fetchRequest.startingToken = currentHistoryToken
        fetchRequest.shouldUnifyResults = true
        let wrapper = CNContactStoreWrapper(store: contactStore)
        let result = wrapper.changeHistoryFetchResult(fetchRequest, error: nil)
        guard let enumerator = result.value as? NSEnumerator else {
            throw ContactError.failedToEnumerateChangeHistory
        }
        currentHistoryToken = result.currentHistoryToken
        continuation?.yield(currentHistoryToken)
        let changeEvents = enumerator.compactMap { $0 as? CNChangeHistoryEvent }
        guard let visitor = eventVisitor else {
            throw ContactError.noEventVisitorAssigned
        }
        for event in changeEvents {
            event.accept(visitor)
        }
    }
    
    /// Observes `CNContactStoreDidChange` notifications and triggers a change fetch when they occur.
    fileprivate func observeNotifications(){
        NotificationCenter.default
            .publisher(for: .CNContactStoreDidChange)
            .sink { notification in
                Task { @ContactActor in
                    try? await ContactActor.shared.fetchChanges()
                }
            }
            .store(in: &cancellables)
    }
    
    //MARK: Guards
    
    /// Ensures that `NSContactsUsageDescription` is set in the app’s Info.plist.
    ///
    /// - Throws: `ContactError.NSContactsUsageDescriptionNotSet` if the key is not set.
    fileprivate func guardContactUsageDescription() throws {
        guard let _ = Bundle.main.object(forInfoDictionaryKey: "NSContactsUsageDescription") as? String else {
            throw ContactError.NSContactsUsageDescriptionNotSet
        }
    }
    
    /// Ensures that certain operations are not attempted on watchOS, where they are not allowed.
    ///
    /// - Throws: `ContactError.operationNotAllowedOnWatchOS` if run on watchOS.
    fileprivate func guardIfWatchOS() throws {
    #if os(watchOS)
        throw ContactError.operationNotAllowedOnWatchOS
    #endif
    }
    
    /// Verifies that the current authorization status allows read/write operations.
    fileprivate func guardAuthorizationStatus() throws {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            guard CNContactStore.authorizationStatus(for: .contacts) == .authorized ||
                  CNContactStore.authorizationStatus(for: .contacts) == .limited else {
                throw ContactError.unauthorized
            }
        } else {
            guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
                throw ContactError.unauthorized
            }
        }
        #else
        // On platforms where `.limited` is not available, just check for `.authorized`.
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            throw ContactError.unauthorized
        }
        #endif
    }
}

