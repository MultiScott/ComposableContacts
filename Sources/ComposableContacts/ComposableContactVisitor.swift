//
//  ComposableContactVisitor.swift
//  ComposableContacts
//
//  Created by Scott Hoge on 12/9/24.
//

@preconcurrency import Contacts
import Foundation
import Sharing
import IdentifiedCollections
import IssueReporting

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

final class ComposableContactVisitor: NSObject, CNChangeHistoryEventVisitor, @unchecked Sendable {
    
    @Shared(.inMemory("composeable-contact-composable-contacts")) var contacts: IdentifiedArrayOf<ComposableContact> = []
    @Shared(.inMemory("composeable-contact-composable-contact-groups")) var groups: IdentifiedArrayOf<ComposableContactGroup> = []
    
    override init() {
        super.init()
    }
    
    func visit(_ event: CNChangeHistoryDropEverythingEvent) {
        self.$contacts.withLock { contacts in
            contacts = []
        }
        self.$groups.withLock { groups in
            groups = []
        }
    }
    
    func visit(_ event: CNChangeHistoryAddContactEvent) {
        let composableContact = ComposableContact(event.contact)
        let result = self.$contacts.withLock { [contact = composableContact] contacts in
            contacts.append(contact)
        }
        if result.inserted == false {
            reportIssue("Failed to insert contact with identifier \(composableContact.id)")
        }
    }
    
    func visit(_ event: CNChangeHistoryUpdateContactEvent) {
        let composableContact = ComposableContact(event.contact)
        //find the index of the current contact to preserve the order
        guard let index = contacts.firstIndex(where: {$0.id == composableContact.id }) else {
            reportIssue("Failed to find contact with identifier \(composableContact.id)")
            return
        }
        self.$contacts.withLock { [contact = composableContact, index = index] contacts in
            contacts[index] = contact
        }
    }
    
    func visit(_ event: CNChangeHistoryDeleteContactEvent) {
       let identifer = event.contactIdentifier
        self.$contacts.withLock { [identifer = identifer] contacts in
            contacts.removeAll(where: {$0.id == identifer})
        }
    }
    
    func delete(_ contactIdentifier: String) {
        guard let index = contacts.firstIndex(where: {$0.id == contactIdentifier }) else {
            reportIssue("Failed to find contact with identifier \(contactIdentifier)")
            return
        }
        let _ = self.$contacts.withLock { [ index = index] contacts in
            contacts.remove(at: index)
        }
    }
    
    func visit(_ event: CNChangeHistoryAddGroupEvent) {
        let composableGroup = ComposableContactGroup(event.group)
        
        let result = $groups.withLock { groups in
            groups.append(composableGroup)
        }
        if result.inserted == false {
            reportIssue("Failed to insert group with identifier \(composableGroup.id)")
        }
    }
    
    func visit(_ event: CNChangeHistoryUpdateGroupEvent) {
        guard let index = groups.firstIndex(where: {$0.id == event.group.identifier }) else {
            reportIssue("Failed to find group with identifier \(event.group.identifier)")
            return
        }
        let composableGroup = ComposableContactGroup(event.group)
        $groups.withLock { groups in
            groups[index] = composableGroup
        }
    }
    
    func visit(_ event: CNChangeHistoryDeleteGroupEvent) {
        guard let index = groups.firstIndex(where: {$0.id == event.groupIdentifier }) else {
            reportIssue("Failed to find group with identifier \(event.groupIdentifier)")
            return
        }
        _ = $groups.withLock { groups in
            groups.remove(at: index)
        }
    }
    
    func visitAddMember(_ event: CNChangeHistoryAddMemberToGroupEvent) {
        let groupID = event.group.identifier
        let contactID = event.member.identifier
        guard let index = groups.firstIndex(where: {$0.id == groupID }) else {
            reportIssue("Failed to find group with identifier \(groupID)")
            return
        }
        var group = groups[index]
        group.contacts.insert(contactID)
        $groups.withLock { groups in
            groups[index] = group
        }
    }
    
    func visitAddSubgroup(_ event: CNChangeHistoryAddSubgroupToGroupEvent) {
        let groupID = event.group.identifier
        let subGroupID = event.subgroup.identifier
        guard let index = groups.firstIndex(where: {$0.id == groupID }) else {
            reportIssue("Failed to find group with identifier \(groupID)")
            return
        }
        var group = groups[index]
        group.subGroups.insert(subGroupID)
        $groups.withLock { groups in
            groups[index] = group
        }
    }
    
    func visitRemoveMember(_ event: CNChangeHistoryRemoveMemberFromGroupEvent) {
        let groupID = event.group.identifier
        let contactID = event.member.identifier
        guard let index = groups.firstIndex(where: {$0.id == groupID }) else {
            reportIssue("Failed to find group with identifier \(groupID)")
            return
        }
        var group = groups[index]
        group.contacts.remove(contactID)
        $groups.withLock { groups in
            groups[index] = group
        }
    }
    
    func visitRemoveSubgroup(_ event: CNChangeHistoryRemoveSubgroupFromGroupEvent) {
        let groupID = event.group.identifier
        let subGroupID = event.subgroup.identifier
        guard let index = groups.firstIndex(where: {$0.id == groupID }) else {
            reportIssue("Failed to find group with identifier \(groupID)")
            return
        }
        var group = groups[index]
        group.subGroups.remove(subGroupID)
        $groups.withLock { groups in
            groups[index] = group
        }
    }
}
