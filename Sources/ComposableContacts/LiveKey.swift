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
import IdentifiedCollections
import Sharing
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
            getAllContacts: {keys in try await ContactActor.shared.getAllContacts(with: keys)},
            getContact: {request in try await ContactActor.shared.getContact(for: request.identifier, and: request.keysToFetch)},
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
            getAllContainers: { try await ContactActor.shared.getContainers() },
            getContainerForContactID: {contactID in try await ContactActor.shared.getContainerForContact(with: contactID) },
            getContainerOfGroupWithID: {ID in try await ContactActor.shared.getContainerOfGroup(with: ID) },
            getContainerOfGroupsWithIDs: {IDs in try await ContactActor.shared.getContainerForGoups(with: IDs) },
            getAllGroups: { try await ContactActor.shared.getGroups() },
            getAllGroupsWithIdentifiers: {IDs in try await ContactActor.shared.getGroups(with: IDs) },
            getAllGroupsInContainerWithID: {ID in try await ContactActor.shared.getGroupsInContainer(with: ID) }
        )
    }
}

@globalActor
public final actor ContactActor {
    public static let shared = ContactActor()
    
    private var cancellables: Set<AnyCancellable> = []
    private let contactStore = CNContactStore()
    private var currentHistoryToken: Data?
    private var eventVisitor : CNChangeHistoryEventVisitor?
    
    //MARK: Authorization
    
    /// Retrieves the current authorization status for accessing the user's contacts.
    /// - Returns: The current authorization status (`CNAuthorizationStatus`) indicating whether the client is authorized, restricted, denied, or not determined.
    fileprivate func checkAuthorization() -> CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }
    
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
    
    fileprivate func configureActor(with config: ComposableContactConfig) throws {
        currentHistoryToken = config.historyToken
        eventVisitor = config.eventVisitor
        observeNotifications()
    }
    
    //MARK: Contact Retrieval
    
    fileprivate func getContact(for id: String, and keysToFetch: Set<ComposableContactKey>) throws -> CNContact {
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let cnKeysToFetch = updatedKeys.map { $0.keyDescriptor }
        let cnContact = try contactStore.unifiedContact(withIdentifier: id, keysToFetch: cnKeysToFetch)
        return cnContact
    }
    
    fileprivate func getAllContacts(with keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        try guardAuthorizationStatus()
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let request = CNContactFetchRequest(keysToFetch: updatedKeys.map {$0.keyDescriptor})
        var contacts: [CNContact] = []
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        return contacts
    }
    
    fileprivate func getContacts(withIdentifiers identifiers: [String], and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(withIdentifiers: identifiers)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    fileprivate func getContacts(matchingphoneNumber phoneNumber: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let phoneNumber = CNPhoneNumber(stringValue: phoneNumber)
        let pred = CNContact.predicateForContacts(matching: phoneNumber)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    fileprivate func getContacts(matchingName name: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(matchingName: name)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    fileprivate func getContacts(matchingEmailAddress emailAddress: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(matchingEmailAddress: emailAddress)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    fileprivate func getContacts(inGroup groupIdentifier: String, and keysToFetch:Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContactsInGroup(withIdentifier: groupIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    fileprivate func getContacts(inContainer containerIdentifier: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContactsInContainer(withIdentifier: containerIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    fileprivate func getContacts(matching predicate: NSPredicate, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        try guardAuthorizationStatus()
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let cnKeysToFetch = updatedKeys.map { $0.keyDescriptor }
        let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: cnKeysToFetch)
        return cnContacts
    }
    
    //MARK: Contact Writes
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
    
    fileprivate func modifyContact(contact: CNContact) async throws {
        try guardIfWatchOS()
        try guardAuthorizationStatus()
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            throw ContactError.failedToCreateMutableCopy
        }
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)
        try contactStore.execute(saveRequest)
    }
    
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
    
    fileprivate func getContainers(matching predicate:  NSPredicate? = nil) throws -> [CNContainer] {
        try guardAuthorizationStatus()
        return try contactStore.containers(matching: predicate)
    }
    
    fileprivate func getContainerForContact(with id: String) async throws -> CNContainer {
        let pred = CNContainer.predicateForContainerOfContact(withIdentifier: id)
        let containers = try getContainers(matching: pred)
        guard let container = containers.first else {
            throw ContactError.failedToFindContainerForContact(id)
        }
        return container
    }
    
    fileprivate func getContainerOfGroup(with id: String) async throws -> CNContainer {
        let pred = CNContainer.predicateForContainerOfGroup(withIdentifier: id)
        let containers = try getContainers(matching: pred)
        guard let container = containers.first else {
            throw ContactError.failedToFindContainerForGroup(id)
        }
        return container
    }
    
    fileprivate func getContainerForGoups(with identifiers: [String])async  throws -> [CNContainer] {
        let pred = CNContainer.predicateForContainers(withIdentifiers: identifiers)
        let containers = try getContainers(matching: pred)
        return containers
    }
    
    //MARK: Group Retrieval
    
    fileprivate func getGroups(matching predicate:  NSPredicate? = nil) throws -> [CNGroup] {
        try guardAuthorizationStatus()
        return try contactStore.groups(matching: predicate)
    }
    
    fileprivate func getGroups(with identifiers: [String]) async throws -> [CNGroup]{
        let pred = CNGroup.predicateForGroups(withIdentifiers: identifiers)
        return try getGroups(matching: pred)
    }
    
    fileprivate func getGroupsInContainer(with id: String) async throws -> CNGroup {
        let pred = CNGroup.predicateForGroupsInContainer(withIdentifier: id)
        let groups = try getGroups(matching: pred)
        guard let group = groups.first else {
            throw ContactError.failedToFindGroupForID(id)
        }
        return group
    }
    
    fileprivate func fetchChanges() throws {
        try guardAuthorizationStatus()
        let fetchRequest = CNChangeHistoryFetchRequest()
        fetchRequest.startingToken = self.currentHistoryToken
        fetchRequest.shouldUnifyResults = true
        let wrapper = CNContactStoreWrapper(store: contactStore)
        let result = wrapper.changeHistoryFetchResult(fetchRequest, error: nil)
        guard let enumerator = result.value as? NSEnumerator else {
            throw ContactError.failedToEnumerateChangeHistory
        }
        self.currentHistoryToken = result.currentHistoryToken
        let changeEvents = enumerator.compactMap { $0 as? CNChangeHistoryEvent }
        guard let visitor = eventVisitor else {
            throw ContactError.noEventVisitorAssigned
        }
        for event in changeEvents {
            event.accept(visitor)
        }
    }
    
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
    
    fileprivate func guardContactUsageDescription() throws {
        guard let _ = Bundle.main.object(forInfoDictionaryKey: "NSContactsUsageDescription") as? String else {
            throw ContactError.NSContactsUsageDescriptionNotSet
        }
    }
    
    fileprivate func guardIfWatchOS() throws {
    #if os(watchOS)
        throw ContactError.operationNotAllowedOnWatchOS
    #endif
    }
    
    fileprivate func guardAuthorizationStatus() throws {
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
    }
}

