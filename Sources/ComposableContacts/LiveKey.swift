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
    
    func requestAccess() async throws -> CNAuthorizationStatus {
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard currentStatus == .notDetermined else {
            return currentStatus
        }
        let _ = try await contactStore.requestAccess(for: .contacts)
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    func getAllContacts(with keysToFetch: [ComposableContactKey]) throws -> [ComposableContact] {
        try checkAuthorizationStatus()
        let request = CNContactFetchRequest(keysToFetch: keysToFetch.map {$0.keyDescriptor})
        var contacts: [ComposableContact] = []
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(ComposableContact(contact))
        }
        return contacts
    }
    
    func getContact(for id: ComposableContact.ID, and keysToFetch: [ComposableContactKey]) throws -> ComposableContact {
        let cnKeysToFetch = keysToFetch.map { $0.keyDescriptor }
        let cnContact = try contactStore.unifiedContact(withIdentifier: id, keysToFetch: cnKeysToFetch)
        return ComposableContact(cnContact)
    }
    
    func getContacts(with identifiers: [ComposableContact.ID], and keysToFetch: [ComposableContactKey]) throws -> [ComposableContact] {
        let pred = CNContact.predicateForContacts(withIdentifiers: identifiers)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(matching phoneNumber: String, and keysToFetch: [ComposableContactKey]) throws -> [ComposableContact] {
        let phoneNumber = CNPhoneNumber(stringValue: phoneNumber)
        let pred = CNContact.predicateForContacts(matching: phoneNumber)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(matchingName name: String, and keysToFetch: [ComposableContactKey]) throws -> [ComposableContact] {
        let pred = CNContact.predicateForContacts(matchingName: name)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(matchingEmailAddress emailAddress: String, and keysToFetch: [ComposableContactKey]) throws -> [ComposableContact] {
        let pred = CNContact.predicateForContacts(matchingEmailAddress: emailAddress)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(inGroup groupIdentifier: String, and keysToFetch: [ComposableContactKey]) throws -> [ComposableContact] {
        let pred = CNContact.predicateForContactsInGroup(withIdentifier: groupIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    func getContacts(inContainer containerIdentifier: String, and keysToFetch: [ComposableContactKey]) throws -> [ComposableContact] {
        let pred = CNContact.predicateForContactsInContainer(withIdentifier: containerIdentifier)
        return try getContacts(matching: pred, and: keysToFetch)
    }
    
    private func getContacts(matching predicate: NSPredicate, and keysToFetch: [ComposableContactKey]) throws -> [ComposableContact] {
        try checkAuthorizationStatus()
        let cnKeysToFetch = keysToFetch.map { $0.keyDescriptor }
        let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: cnKeysToFetch)
        return cnContacts.map {ComposableContact($0)}
    }
    
    func saveContact() {
        let contact = CNContact.mutableCopy() as? CNMutableContact
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

