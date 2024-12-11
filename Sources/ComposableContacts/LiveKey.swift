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


public extension SharedReaderKey where Self == InMemoryKey<IdentifiedArrayOf<ComposableContact>> {
  static var composableContacts: Self {
    inMemory("composableContacts")
  }
}

public extension SharedReaderKey where Self == InMemoryKey<IdentifiedArrayOf<ComposableContact>>.Default {
  static var composableContacts: Self {
      Self[.composableContacts,
         default: []]
  }
}

// MARK: Live
@available(iOSApplicationExtension, unavailable)
extension ContactsClient: DependencyKey {
    // Map Interface to live methods
    public static var liveValue: Self {
        let contactActor = ContactActor()
        return Self(
            checkAccess: { .authorized },
            requestAccess: { try await contactActor.requestAccess() },
            getDataForContacts: {_ in []},
            getDataForContact: {_ in .johnDoe},
            getKeyForContact: {""},
            initSharedComposableContacts: {""}
        )
    }
}

@globalActor
public final actor ContactActor {
    public static let shared = ContactActor()
    
    private var cancellables: Set<AnyCancellable> = []
    private var composeableContactVisitor = ComposableContactVisitor()
    private let contactStore = CNContactStore()
    private var currentHistoryToken: Data? {
            get {
                if usingSharedComposableContacts {
                    return historyToken
                } else {
                    return externalHistoryToken
                }
            }
            set {
                if usingSharedComposableContacts {
                    $historyToken.withLock { token in
                        token = newValue
                    }
                } else {
                    externalHistoryToken = newValue
                }
            }
        }
    
    private var externalHistoryToken: Data?
    
    private var externalVisitor: CNChangeHistoryEventVisitor?
    private var eventVisitor : CNChangeHistoryEventVisitor? {
        get {
            if usingSharedComposableContacts {
                return composeableContactVisitor
            } else {
                return externalVisitor
            }
        }
    }
    
    private var usingSharedComposableContacts: Bool = false
    
    @Shared(.appStorage("composeable-contact-client-history-token")) var historyToken: Data?
    @Shared(.inMemory("composeable-contact-composable-contact-groups")) var groups: IdentifiedArrayOf<ComposableContactGroup> = []
    @Shared(.inMemory("composeable-contact-composable-contact-containers")) var containers: [ComposableContactContainer] = []
    
    func initSharedComposableContacts() throws {
        usingSharedComposableContacts = true
        try initContacts()
        initGroups()
        initContainers()
        observeNotifications()
    }
    
    func initSharedExternalConfig(config: ComposableContactClientConfig) throws {
        usingSharedComposableContacts = false
        externalVisitor = config.eventVisitor
        currentHistoryToken = config.historyToken
        try initContacts()
        observeNotifications()
    }
    
    private func initContacts() throws {
        try fetchChanges()
    }
    
    private func initGroups() {
        do {
            let cnGroups = try getGroups()
            let composeableGroups = cnGroups.map{ ComposableContactGroup($0)}
            $groups.withLock { groups in
                groups.append(contentsOf: composeableGroups) 
            }
        } catch {
            reportIssue("Failed to initalize groups, will fall back to default empty value")
        }
    }
    
    private func initContainers() {
        do {
            let cnContainers = try getContainers()
            let composeableGroups = cnContainers.map{ ComposableContactContainer($0)}
            $containers.withLock { containers in
                containers = composeableGroups
            }
        } catch {
            reportIssue("Failed to initalize containers, will fall back to default empty value")
        }
    }
    
    func requestAccess() async throws -> CNAuthorizationStatus {
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard currentStatus == .notDetermined else {
            return currentStatus
        }
        let _ = try await contactStore.requestAccess(for: .contacts)
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    func getAllContacts(with keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        try checkAuthorizationStatus()
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let request = CNContactFetchRequest(keysToFetch: updatedKeys.map {$0.keyDescriptor})
        var contacts: [CNContact] = []
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        return contacts
    }
    
    @discardableResult
    func getContact(for id: String, and keysToFetch: Set<ComposableContactKey>) throws -> CNContact {
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let cnKeysToFetch = updatedKeys.map { $0.keyDescriptor }
        let cnContact = try contactStore.unifiedContact(withIdentifier: id, keysToFetch: cnKeysToFetch)
        return cnContact
    }
    
    @discardableResult
    func getContacts(with identifiers: [String], and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(withIdentifiers: identifiers)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    @discardableResult
    func getContacts(matching phoneNumber: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let phoneNumber = CNPhoneNumber(stringValue: phoneNumber)
        let pred = CNContact.predicateForContacts(matching: phoneNumber)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    @discardableResult
    func getContacts(matchingName name: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(matchingName: name)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    @discardableResult
    func getContacts(matchingEmailAddress emailAddress: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(matchingEmailAddress: emailAddress)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    @discardableResult
    func getContacts(inGroup groupIdentifier: String, and keysToFetch:Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContactsInGroup(withIdentifier: groupIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    @discardableResult
    func getContacts(inContainer containerIdentifier: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContactsInContainer(withIdentifier: containerIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContainers(matching predicate:  NSPredicate? = nil) throws -> [CNContainer] {
        try checkAuthorizationStatus()
        return try contactStore.containers(matching: predicate)
    }
    
    func getContainerForContact(with id: String) throws -> CNContainer {
        let pred = CNContainer.predicateForContainerOfContact(withIdentifier: id)
        let containers = try getContainers(matching: pred)
        guard let container = containers.first else {
            throw ContactError.failedToFindContainerForContact(id)
        }
        return container
    }
    
    func getContainerForGroup(with id: String) throws -> CNContainer {
        let pred = CNContainer.predicateForContainerOfGroup(withIdentifier: id)
        let containers = try getContainers(matching: pred)
        guard let container = containers.first else {
            throw ContactError.failedToFindContainerForGroup(id)
        }
        return container
    }
    
    func getContainerForGoup(with identifiers: [String]) throws -> [CNContainer] {
        let pred = CNContainer.predicateForContainers(withIdentifiers: identifiers)
        let containers = try getContainers(matching: pred)
        return containers
    }
    
    func getGroups(matching predicate:  NSPredicate? = nil) throws -> [CNGroup] {
        try checkAuthorizationStatus()
        return try contactStore.groups(matching: predicate)
    }
    
    func getGroups(with identifiers: [String]) throws -> [CNGroup]{
        let pred = CNGroup.predicateForGroups(withIdentifiers: identifiers)
        return try getGroups(matching: pred)
    }
    
    func getGroupsInContainer(with id: String) throws -> CNGroup {
        let pred = CNGroup.predicateForGroupsInContainer(withIdentifier: id)
        let groups = try getGroups(matching: pred)
        guard let group = groups.first else {
            throw ContactError.failedToFindGroupForID(id)
        }
        return group
    }
    
    private func getContacts(matching predicate: NSPredicate, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        try checkAuthorizationStatus()
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let cnKeysToFetch = updatedKeys.map { $0.keyDescriptor }
        let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: cnKeysToFetch)
        return cnContacts
    }
    
    func fetchChanges() throws {
        try checkAuthorizationStatus()
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
        for event in changeEvents {
            if let eventVisitor = eventVisitor {
                event.accept(eventVisitor)
            } else {
                event.accept(composeableContactVisitor)
            }
        }
    }
    
    func observeNotifications(){
        NotificationCenter.default
            .publisher(for: .CNContactStoreDidChange)
            .sink { notification in
                Task { @ContactActor in
                    try? await ContactActor.shared.fetchChanges()
                }
            }
            .store(in: &cancellables)
    }
    
    //MARK: Save New Contact
    func createNewContact(contact: CNContact, to containerWithIdentifier: String? = nil) throws {
        try checkIfWatchOS()
        try checkAuthorizationStatus()
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            throw ContactError.failedToCreateMutableCopy
        }
        let saveRequest = CNSaveRequest()
        saveRequest.add(mutableContact, toContainerWithIdentifier: containerWithIdentifier)
        try contactStore.execute(saveRequest)
    }
    
    func createNewContacts(contacts: Set<CNContact>, to containerWithIdentifier: String? = nil) throws {
        try checkIfWatchOS()
        try checkAuthorizationStatus()
        let saveRequest = CNSaveRequest()
        var mutableContacts: [CNMutableContact] = []
        for contact in contacts {
            guard let newContact = contact.mutableCopy() as? CNMutableContact else {
                throw ContactError.failedToCreateMutableCopy
            }
            saveRequest.add(newContact, toContainerWithIdentifier: containerWithIdentifier)
            mutableContacts.append(newContact)
        }
        try contactStore.execute(saveRequest)
    }
    
    //MARK: Modify Contact
    func modifyContact(contact: CNContact) throws {
        try checkIfWatchOS()
        try checkAuthorizationStatus()
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            throw ContactError.failedToCreateMutableCopy
        }
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)
        try contactStore.execute(saveRequest)
    }
    
    //MARK: Checks
    private func checkIfWatchOS() throws {
    #if os(watchOS)
        throw ContactError.operationNotAllowed
    #endif
    }
    
    private func checkAuthorizationStatus() throws {
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

