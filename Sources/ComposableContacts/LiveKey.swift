//
//  ContactLiveKey.swift
//  MultiOnBrowser
//
//  Created by Scott Hoge on 12/3/24.
//

///Per Apple Documentation:
///A CNContact object stores an immutable copy of a contact’s information, so you cannot change the information in this object directly. Contact objects are thread-safe, so you may access them from any thread of your app.
@preconcurrency import Contacts
import Dependencies

// MARK: Live
@available(iOSApplicationExtension, unavailable)
extension ContactsClient: DependencyKey {
    // Map Interface to live methods
    public static var liveValue: Self {
        let contactActor = ContactActor()
        return Self(
            requestAccess: { try await contactActor.requestAccess() },
            getDataForContacts: {_ in []},
            getDataForContact: {_ in .johnDoe},
            getKeyForContact: {""}
        )
    }
}

public final actor ContactActor {
    let contactStore = CNContactStore()
    var currentHistoryToken: Data?
    init(currentHistoryToken: Data? = nil) {
        if let currentHistoryToken = currentHistoryToken {
            self.currentHistoryToken = currentHistoryToken
        } else {
            self.currentHistoryToken = contactStore.currentHistoryToken
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
    
    func getContact(for id: String, and keysToFetch: Set<ComposableContactKey>) throws -> CNContact {
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let cnKeysToFetch = updatedKeys.map { $0.keyDescriptor }
        let cnContact = try contactStore.unifiedContact(withIdentifier: id, keysToFetch: cnKeysToFetch)
        return cnContact
    }
    
    func getContacts(with identifiers: [String], and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(withIdentifiers: identifiers)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(matching phoneNumber: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let phoneNumber = CNPhoneNumber(stringValue: phoneNumber)
        let pred = CNContact.predicateForContacts(matching: phoneNumber)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(matchingName name: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(matchingName: name)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(matchingEmailAddress emailAddress: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContacts(matchingEmailAddress: emailAddress)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(inGroup groupIdentifier: String, and keysToFetch:Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContactsInGroup(withIdentifier: groupIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(inContainer containerIdentifier: String, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        let pred = CNContact.predicateForContactsInContainer(withIdentifier: containerIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    private func getContacts(matching predicate: NSPredicate, and keysToFetch: Set<ComposableContactKey>) throws -> [CNContact] {
        try checkAuthorizationStatus()
        var updatedKeys = keysToFetch
        updatedKeys.insert(.identifier)
        let cnKeysToFetch = updatedKeys.map { $0.keyDescriptor }
        let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: cnKeysToFetch)
        return cnContacts
    }
    
    @objc func fetchChanges() async throws -> [CNContact: Bool] {
        let fetchRequest = CNChangeHistoryFetchRequest()
        fetchRequest.startingToken = self.currentHistoryToken
        var contactChanges: [CNContact: CNContactChangeAction] = [:]
        fetchRequest.shouldUnifyResults = true
        fetchRequest
//        try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
//        }
        
//        try contactStore.enumerateChanges(fetchRequest) { event, stop in
//                    switch event {
//                    case let addContactEvent as CNChangeHistoryAddContactEvent:
//                        print("Added Contact: \(addContactEvent.contact.identifier)")
//                        // Handle adding to your local store
//
//                    case let updateContactEvent as CNChangeHistoryUpdateContactEvent:
//                        print("Updated Contact: \(updateContactEvent.contact.identifier)")
//                        // Handle updating in your local store
//
//                    case let deleteContactEvent as CNChangeHistoryDeleteContactEvent:
//                        print("Deleted Contact with ID: \(deleteContactEvent.contactIdentifier)")
//                        // Handle deletion in your local store
//
//                    case let addGroupEvent as CNChangeHistoryAddGroupEvent:
//                        print("Added Group: \(addGroupEvent.group.identifier)")
//                        // Handle group addition if needed
//
//                    case let updateGroupEvent as CNChangeHistoryUpdateGroupEvent:
//                        print("Updated Group: \(updateGroupEvent.group.identifier)")
//                        // Handle group updates if needed
//
//                    case let deleteGroupEvent as CNChangeHistoryDeleteGroupEvent:
//                        print("Deleted Group with ID: \(deleteGroupEvent.groupIdentifier)")
//                        // Handle group deletion if needed
//
//                    case let addMemberEvent as CNChangeHistoryAddMemberToGroupEvent:
//                        print("Added member \(addMemberEvent.member.contactIdentifier) to group \(addMemberEvent.groupIdentifier)")
//                        // Handle member addition
//
//                    case let removeMemberEvent as CNChangeHistoryRemoveMemberFromGroupEvent:
//                        print("Removed member \(removeMemberEvent.member.contactIdentifier) from group \(removeMemberEvent.groupIdentifier)")
//                        // Handle member removal
//
//                    default:
//                        break
//                    }
//                }
        return [:]
    }
    
    //MARK: Save New Contact
    func createNewContact(contact: CNContact, to containerWithIdentifier: String? = nil) throws -> CNContact {
        try checkIfWatchOS()
        try checkAuthorizationStatus()
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            throw ContactError.failedToCreateMutableCopy
        }
        let saveRequest = CNSaveRequest()
        saveRequest.add(mutableContact, toContainerWithIdentifier: containerWithIdentifier)
        try contactStore.execute(saveRequest)
        return try getContact(for: mutableContact.identifier, and: mutableContact.getSetKeys())
    }
    
    func createNewContacts(contacts: Set<CNContact>, to containerWithIdentifier: String? = nil) throws -> [CNContact] {
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
        var newContacts: [CNContact] = []
        //Need to iterate through each contact to determine which keys are needed and only fetch those. Otherwise would batch
        for contact in mutableContacts {
            let keysToFetch = contact.getSetKeys()
            let newContact = try getContact(for: contact.identifier, and: keysToFetch)
            newContacts.append(newContact)
        }
        return newContacts
    }
    
    //MARK: Modify Contact
    func modifyContact(contact: CNContact) throws -> CNContact {
        try checkIfWatchOS()
        try checkAuthorizationStatus()
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            throw ContactError.failedToCreateMutableCopy
        }
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)
        try contactStore.execute(saveRequest) 
        let keySet = contact.getFetchedKeys()
        return try getContact(for: contact.identifier, and: keySet)
    }
    
    
    
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

