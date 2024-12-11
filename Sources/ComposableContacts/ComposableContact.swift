//
//  ComposableContact.swift
//  ComposableContacts
//
//  Created by Scott Hoge on 12/4/24.
//

import Foundation
@preconcurrency import Contacts
import IssueReporting

public struct ComposableContactGroup: Codable, Identifiable, Sendable {
    public var id: String
    var name: String
    var subGroups: Set<ComposableContactGroup.ID> = []
    var contacts: Set<ComposableContact.ID> = []
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    init(_ group: CNGroup) {
        self.id = group.identifier
        self.name = group.name
    }
}

public struct ComposableContactContainer: Codable, Identifiable, Sendable {
    public var id: String
    var name: String
    var type: ContainerType
    
    init(_ group: CNContainer) {
        self.id = group.identifier
        self.name = group.name
        self.type = ContainerType(type: group.type)
    }
    
    enum ContainerType: Int, Codable, Sendable {
        case local
        case exchange
        case cardDAV
        case unassigned
        
        init(type: CNContainerType) {
            guard let mapped = ContainerType(rawValue: type.rawValue) else {
                self = .unassigned
                reportIssue("Warning: Failed to map CNContainerType to ComposableContactContainer.type. Defaulting to .unassigned")
                return
            }
            self = mapped
        }
        
        func toCNContainerType() -> CNContainerType {
            guard let mapped = CNContainerType(rawValue: self.rawValue) else {
                reportIssue("Warning: Failed to map ComposableContactContainer.type to CNContainerType. Defaulting to .unassigned")
                return .unassigned
            }
            return mapped
        }
    }
}

// Define Sendable structs with optional fields
public struct ComposableContact: Codable, Identifiable, Sendable {
    public let id: String
//    let identifier: String
    let contactType: ContactType?
    let namePrefix: String?
    let givenName: String?
    let middleName: String?
    let familyName: String?
    let previousFamilyName: String?
    let nameSuffix: String?
    let nickname: String?
    let organizationName: String?
    let departmentName: String?
    let jobTitle: String?
    let phoneticGivenName: String?
    let phoneticMiddleName: String?
    let phoneticFamilyName: String?
    let phoneticOrganizationName: String?
    let birthday: DateComponents?
    let nonGregorianBirthday: DateComponents?
    let note: String?
    let imageData: Data?
    let thumbnailImageData: Data?
    let imageDataAvailable: Bool?
    let phoneNumbers: [LabeledValue<PhoneNumber>]?
    let emailAddresses: [LabeledValue<String>]?
    let postalAddresses: [LabeledValue<PostalAddress>]?
    let urlAddresses: [LabeledValue<String>]?
    let contactRelations: [LabeledValue<ContactRelation>]?
    let socialProfiles: [LabeledValue<SocialProfile>]?
    let instantMessageAddresses: [LabeledValue<InstantMessageAddress>]?
    let dates: [LabeledValue<DateComponents>]?
    
    struct LabeledValue<Value: Codable & Sendable>: Codable, Sendable {
        let label: String?
        let value: Value?
    }

    struct PhoneNumber: Codable, Sendable  {
        let stringValue: String?
    }
    
    enum ContactType: Int, Codable, Sendable {
        case person = 0
        case organization = 1
        case unknown = -1
        
        init(type: CNContactType) {
            guard let mapped = ContactType(rawValue: type.rawValue) else {
                self = .unknown
                return
            }
            self = mapped
        }
        
        func toCNContactType() -> CNContactType {
            guard let mapped = CNContactType(rawValue: self.rawValue) else {
                reportIssue("Warning: Encountered unknown contact type. Defaulting to .person")
                return .person
            }
            return mapped
        }
    }

    struct PostalAddress: Codable, Sendable {
        let street: String?
        let city: String?
        let state: String?
        let postalCode: String?
        let country: String?
        let isoCountryCode: String?
        let subAdministrativeArea: String?
        let subLocality: String?
    }

    struct ContactRelation: Codable, Sendable {
        let name: String?
    }

    struct SocialProfile: Codable, Sendable {
        let urlString: String?
        let username: String?
        let userIdentifier: String?
        let service: String?
    }

    struct InstantMessageAddress: Codable, Sendable {
        let username: String?
        let service: String?
    }
    
    init(identifier: String,
         contactType: ContactType?,
         namePrefix: String?,
         givenName: String?,
         middleName: String?,
         familyName: String?,
         previousFamilyName: String?,
         nameSuffix: String?,
         nickname: String?,
         organizationName: String?,
         departmentName: String?,
         jobTitle: String?,
         phoneticGivenName: String?,
         phoneticMiddleName: String?,
         phoneticFamilyName: String?,
         phoneticOrganizationName: String?,
         birthday: DateComponents?,
         nonGregorianBirthday: DateComponents?,
         note: String?,
         imageData: Data?,
         thumbnailImageData: Data?,
         imageDataAvailable: Bool?,
         phoneNumbers: [LabeledValue<PhoneNumber>]?,
         emailAddresses: [LabeledValue<String>]?,
         postalAddresses: [LabeledValue<PostalAddress>]?,
         urlAddresses: [LabeledValue<String>]?,
         contactRelations: [LabeledValue<ContactRelation>]?,
         socialProfiles: [LabeledValue<SocialProfile>]?,
         instantMessageAddresses: [LabeledValue<InstantMessageAddress>]?,
         dates: [LabeledValue<DateComponents>]?) {
        self.id = identifier
        self.contactType = contactType
        self.namePrefix = namePrefix
        self.givenName = givenName
        self.middleName = middleName
        self.familyName = familyName
        self.previousFamilyName = previousFamilyName
        self.nameSuffix = nameSuffix
        self.nickname = nickname
        self.organizationName = organizationName
        self.departmentName = departmentName
        self.jobTitle = jobTitle
        self.phoneticGivenName = phoneticGivenName
        self.phoneticMiddleName = phoneticMiddleName
        self.phoneticFamilyName = phoneticFamilyName
        self.phoneticOrganizationName = phoneticOrganizationName
        self.birthday = birthday
        self.nonGregorianBirthday = nonGregorianBirthday
        self.note = note
        self.imageData = imageData
        self.thumbnailImageData = thumbnailImageData
        self.imageDataAvailable = imageDataAvailable
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.postalAddresses = postalAddresses
        self.urlAddresses = urlAddresses
        self.contactRelations = contactRelations
        self.socialProfiles = socialProfiles
        self.instantMessageAddresses = instantMessageAddresses
        self.dates = dates
    }


}

/// An enum representing all possible keys for accessing fields in a `ComposableContact`. They map to  the corresponding `CNKeyDescriptor` via the `keyDescriptor` variable.
public enum ComposableContactKey: CaseIterable, Codable, Sendable, Equatable, Hashable {
    case identifier
    case contactType
    case namePrefix
    case givenName
    case middleName
    case familyName
    case previousFamilyName
    case nameSuffix
    case nickname
    case organizationName
    case departmentName
    case jobTitle
    case phoneticGivenName
    case phoneticMiddleName
    case phoneticFamilyName
    case phoneticOrganizationName
    case birthday
    case nonGregorianBirthday
    case note
    case imageData
    case thumbnailImageData
    case imageDataAvailable
    case phoneNumbers
    case emailAddresses
    case postalAddresses
    case urlAddresses
    case contactRelations
    case socialProfiles
    case instantMessageAddresses
    case dates

    /// Maps the enum case to its corresponding `CNKeyDescriptor` value.
    /// This property integrates with the `Contacts` framework,
    /// allowing for safe and readable key usage when accessing or requesting contact fields.
    var keyDescriptor: CNKeyDescriptor {
        switch self {
        case .identifier:
            return CNContactIdentifierKey as CNKeyDescriptor
        case .contactType:
            return CNContactTypeKey as CNKeyDescriptor
        case .namePrefix:
            return CNContactNamePrefixKey as CNKeyDescriptor
        case .givenName:
            return CNContactGivenNameKey as CNKeyDescriptor
        case .middleName:
            return CNContactMiddleNameKey as CNKeyDescriptor
        case .familyName:
            return CNContactFamilyNameKey as CNKeyDescriptor
        case .previousFamilyName:
            return CNContactPreviousFamilyNameKey as CNKeyDescriptor
        case .nameSuffix:
            return CNContactNameSuffixKey as CNKeyDescriptor
        case .nickname:
            return CNContactNicknameKey as CNKeyDescriptor
        case .organizationName:
            return CNContactOrganizationNameKey as CNKeyDescriptor
        case .departmentName:
            return CNContactDepartmentNameKey as CNKeyDescriptor
        case .jobTitle:
            return CNContactJobTitleKey as CNKeyDescriptor
        case .phoneticGivenName:
            return CNContactPhoneticGivenNameKey as CNKeyDescriptor
        case .phoneticMiddleName:
            return CNContactPhoneticMiddleNameKey as CNKeyDescriptor
        case .phoneticFamilyName:
            return CNContactPhoneticFamilyNameKey as CNKeyDescriptor
        case .phoneticOrganizationName:
            return CNContactPhoneticOrganizationNameKey as CNKeyDescriptor
        case .birthday:
            return CNContactBirthdayKey as CNKeyDescriptor
        case .nonGregorianBirthday:
            return CNContactNonGregorianBirthdayKey as CNKeyDescriptor
        case .note:
            return CNContactNoteKey as CNKeyDescriptor
        case .imageData:
            return CNContactImageDataKey as CNKeyDescriptor
        case .thumbnailImageData:
            return CNContactThumbnailImageDataKey as CNKeyDescriptor
        case .imageDataAvailable:
            return CNContactImageDataAvailableKey as CNKeyDescriptor
        case .phoneNumbers:
            return CNContactPhoneNumbersKey as CNKeyDescriptor
        case .emailAddresses:
            return CNContactEmailAddressesKey as CNKeyDescriptor
        case .postalAddresses:
            return CNContactPostalAddressesKey as CNKeyDescriptor
        case .urlAddresses:
            return CNContactUrlAddressesKey as CNKeyDescriptor
        case .contactRelations:
            return CNContactRelationsKey as CNKeyDescriptor
        case .socialProfiles:
            return CNContactSocialProfilesKey as CNKeyDescriptor
        case .instantMessageAddresses:
            return CNContactInstantMessageAddressesKey as CNKeyDescriptor
        case .dates:
            return CNContactDatesKey as CNKeyDescriptor
        }
    }
}

//MARK: CNContact methods Values
extension ComposableContact {
    
    init (_ contact: CNContact) {
        // Map properties directly
        let identifier = contact.identifier
        let namePrefix = contact.namePrefix
        let givenName = contact.givenName
        let middleName = contact.middleName
        let familyName = contact.familyName
        let previousFamilyName = contact.previousFamilyName
        let nameSuffix = contact.nameSuffix
        let nickname = contact.nickname
        let organizationName = contact.organizationName
        let departmentName = contact.departmentName
        let jobTitle = contact.jobTitle
        let phoneticGivenName = contact.phoneticGivenName
        let phoneticMiddleName = contact.phoneticMiddleName
        let phoneticFamilyName = contact.phoneticFamilyName
        let phoneticOrganizationName = contact.phoneticOrganizationName
        let birthday = contact.birthday
        let nonGregorianBirthday = contact.nonGregorianBirthday
        let note = contact.note
        let imageData = contact.imageData
        let thumbnailImageData = contact.thumbnailImageData
        let imageDataAvailable = contact.imageDataAvailable
        
        let contactType = ComposableContact.ContactType(type: contact.contactType)

        // Map arrays
        let phoneNumbers = contact.phoneNumbers.map { labeledValue in
            let label = labeledValue.label
            let value = ComposableContact.PhoneNumber(stringValue: labeledValue.value.stringValue)
            return ComposableContact.LabeledValue(label: label, value: value)
        }

        let emailAddresses = contact.emailAddresses.map { labeledValue in
            let label = labeledValue.label
            let value = labeledValue.value as String
            return ComposableContact.LabeledValue(label: label, value: value)
        }

        let postalAddresses = contact.postalAddresses.map { labeledValue in
            let label = labeledValue.label
            let address = labeledValue.value
            let value = ComposableContact.PostalAddress(
                street: address.street,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country,
                isoCountryCode: address.isoCountryCode,
                subAdministrativeArea: address.subAdministrativeArea,
                subLocality: address.subLocality
            )
            return ComposableContact.LabeledValue(label: label, value: value)
        }

        let urlAddresses = contact.urlAddresses.map { labeledValue in
            let label = labeledValue.label
            let value = labeledValue.value as String
            return ComposableContact.LabeledValue(label: label, value: value)
        }

        let contactRelations = contact.contactRelations.map { labeledValue in
            let label = labeledValue.label
            let value = ComposableContact.ContactRelation(name: labeledValue.value.name)
            return ComposableContact.LabeledValue(label: label, value: value)
        }

        let socialProfiles = contact.socialProfiles.map { labeledValue in
            let label = labeledValue.label
            let profile = labeledValue.value
            let value = ComposableContact.SocialProfile(
                urlString: profile.urlString,
                username: profile.username,
                userIdentifier: profile.userIdentifier,
                service: profile.service
            )
            return ComposableContact.LabeledValue(label: label, value: value)
        }

        let instantMessageAddresses = contact.instantMessageAddresses.map { labeledValue in
            let label = labeledValue.label
            let address = labeledValue.value
            let value = ComposableContact.InstantMessageAddress(
                username: address.username,
                service: address.service
            )
            return ComposableContact.LabeledValue(label: label, value: value)
        }

        let dates = contact.dates.map { labeledValue in
            let label = labeledValue.label
            let value = labeledValue.value as DateComponents
            return ComposableContact.LabeledValue(label: label, value: value)
        }
        self.id = identifier
        self.contactType = contactType
        self.namePrefix = namePrefix
        self.givenName = givenName
        self.middleName = middleName
        self.familyName = familyName
        self.previousFamilyName = previousFamilyName
        self.nameSuffix = nameSuffix
        self.nickname = nickname
        self.organizationName = organizationName
        self.departmentName = departmentName
        self.jobTitle = jobTitle
        self.phoneticGivenName = phoneticGivenName
        self.phoneticMiddleName = phoneticMiddleName
        self.phoneticFamilyName = phoneticFamilyName
        self.phoneticOrganizationName = phoneticOrganizationName
        self.birthday = birthday
        self.nonGregorianBirthday = nonGregorianBirthday
        self.note = note
        self.imageData = imageData
        self.thumbnailImageData = thumbnailImageData
        self.imageDataAvailable = imageDataAvailable
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.postalAddresses = postalAddresses
        self.urlAddresses = urlAddresses
        self.contactRelations = contactRelations
        self.socialProfiles = socialProfiles
        self.instantMessageAddresses = instantMessageAddresses
        self.dates = dates
        return
    }

    
    //TODO: Error Handling: Consider adding more robust error handling and validation to handle edge cases, such as missing required fields.
    public func toCNMutableContact() -> CNMutableContact {
        let mutableContact = CNMutableContact()
        
        if let contactType = self.contactType {
            mutableContact.contactType = contactType.toCNContactType()
        }
        
        if let namePrefix = self.namePrefix {
            mutableContact.namePrefix = namePrefix
        }
        
        if let givenName = self.givenName {
            mutableContact.givenName = givenName
        }
        
        if let middleName = self.middleName {
            mutableContact.middleName = middleName
        }
        
        if let familyName = self.familyName {
            mutableContact.familyName = familyName
        }
        
        if let previousFamilyName = self.previousFamilyName {
            mutableContact.previousFamilyName = previousFamilyName
        }
        
        if let nameSuffix = self.nameSuffix {
            mutableContact.nameSuffix = nameSuffix
        }
        
        if let nickname = self.nickname {
            mutableContact.nickname = nickname
        }
        
        if let organizationName = self.organizationName {
            mutableContact.organizationName = organizationName
        }
        
        if let departmentName = self.departmentName {
            mutableContact.departmentName = departmentName
        }
        
        if let jobTitle = self.jobTitle {
            mutableContact.jobTitle = jobTitle
        }
        
        if let phoneticGivenName = self.phoneticGivenName {
            mutableContact.phoneticGivenName = phoneticGivenName
        }
        
        if let phoneticMiddleName = self.phoneticMiddleName {
            mutableContact.phoneticMiddleName = phoneticMiddleName
        }
        
        if let phoneticFamilyName = self.phoneticFamilyName {
            mutableContact.phoneticFamilyName = phoneticFamilyName
        }
        
        if let phoneticOrganizationName = self.phoneticOrganizationName {
            mutableContact.phoneticOrganizationName = phoneticOrganizationName
        }
        
        if let birthday = self.birthday {
            mutableContact.birthday = birthday
        }
        
        if let nonGregorianBirthday = self.nonGregorianBirthday {
            mutableContact.nonGregorianBirthday = nonGregorianBirthday
        }
        
        if let note = self.note {
            mutableContact.note = note
        }
        
        if let imageData = self.imageData {
            mutableContact.imageData = imageData
        }
        
        if let phoneNumbers = self.phoneNumbers {
            mutableContact.phoneNumbers = phoneNumbers.compactMap { labeledValue in
                guard let value = labeledValue.value, let stringValue = value.stringValue else { return nil }
                let phoneNumber = CNPhoneNumber(stringValue: stringValue)
                return CNLabeledValue(label: labeledValue.label, value: phoneNumber)
            }
        }
        
        if let emailAddresses = self.emailAddresses {
            mutableContact.emailAddresses = emailAddresses.compactMap { labeledValue in
                guard let value = labeledValue.value else { return nil }
                return CNLabeledValue(label: labeledValue.label, value: value as NSString)
            }
        }
        
        if let postalAddresses = self.postalAddresses {
            mutableContact.postalAddresses = postalAddresses.compactMap { labeledValue in
                guard let value = labeledValue.value else { return nil }
                let postalAddress = CNMutablePostalAddress()
                postalAddress.street = value.street ?? ""
                postalAddress.city = value.city ?? ""
                postalAddress.state = value.state ?? ""
                postalAddress.postalCode = value.postalCode ?? ""
                postalAddress.country = value.country ?? ""
                postalAddress.isoCountryCode = value.isoCountryCode ?? ""
                postalAddress.subAdministrativeArea = value.subAdministrativeArea ?? ""
                postalAddress.subLocality = value.subLocality ?? ""
                return CNLabeledValue(label: labeledValue.label, value: postalAddress)
            }
        }
        
        if let urlAddresses = self.urlAddresses {
            mutableContact.urlAddresses = urlAddresses.compactMap { labeledValue in
                guard let value = labeledValue.value else { return nil }
                return CNLabeledValue(label: labeledValue.label, value: value as NSString)
            }
        }
        
        if let contactRelations = self.contactRelations {
            mutableContact.contactRelations = contactRelations.compactMap { labeledValue in
                guard let value = labeledValue.value, let name = value.name else { return nil }
                let contactRelation = CNContactRelation(name: name)
                return CNLabeledValue(label: labeledValue.label, value: contactRelation)
            }
        }
        
        if let socialProfiles = self.socialProfiles {
            mutableContact.socialProfiles = socialProfiles.compactMap { labeledValue in
                guard let value = labeledValue.value else { return nil }
                let socialProfile = CNSocialProfile(
                    urlString: value.urlString,
                    username: value.username,
                    userIdentifier: value.userIdentifier,
                    service: value.service
                )
                return CNLabeledValue(label: labeledValue.label, value: socialProfile)
            }
        }
        
        if let instantMessageAddresses = self.instantMessageAddresses {
            mutableContact.instantMessageAddresses = instantMessageAddresses.compactMap { labeledValue in
                guard let value = labeledValue.value else { return nil }
                let imAddress = CNInstantMessageAddress(
                    username: value.username ?? "",
                    service: value.service ?? ""
                )
                return CNLabeledValue(label: labeledValue.label, value: imAddress)
            }
        }
        
        if let dates = self.dates {
            mutableContact.dates = dates.compactMap { labeledValue in
                guard let value = labeledValue.value else { return nil }
                return CNLabeledValue(label: labeledValue.label, value: value as NSDateComponents)
            }
        }
        
        return mutableContact
    }
}

//MARK: Mock Values
extension ComposableContact {

    // "John Doe" instance
    public static let johnDoe = ComposableContact(
        identifier: "john-doe-identifier",
        contactType: .person,
        namePrefix: "Mr.",
        givenName: "John",
        middleName: "A.",
        familyName: "Doe",
        previousFamilyName: nil,
        nameSuffix: nil,
        nickname: "Johnny",
        organizationName: "Doe Industries",
        departmentName: "Engineering",
        jobTitle: "Software Engineer",
        phoneticGivenName: nil,
        phoneticMiddleName: nil,
        phoneticFamilyName: nil,
        phoneticOrganizationName: nil,
        birthday: DateComponents(year: 1985, month: 6, day: 15),
        nonGregorianBirthday: nil,
        note: "Met at the tech conference.",
        imageData: nil,
        thumbnailImageData: nil,
        imageDataAvailable: false,
        phoneNumbers: [
            ComposableContact.LabeledValue(
                label: "mobile",
                value: ComposableContact.PhoneNumber(stringValue: "555-123-4567")
            ),
            ComposableContact.LabeledValue(
                label: "work",
                value: ComposableContact.PhoneNumber(stringValue: "555-987-6543")
            )
        ],
        emailAddresses: [
            ComposableContact.LabeledValue(label: "personal", value: "john.doe@example.com"),
            ComposableContact.LabeledValue(label: "work", value: "j.doe@doeindustries.com")
        ],
        postalAddresses: [
            ComposableContact.LabeledValue(
                label: "home",
                value: ComposableContact.PostalAddress(
                    street: "123 Main St",
                    city: "Anytown",
                    state: "CA",
                    postalCode: "12345",
                    country: "USA",
                    isoCountryCode: "US",
                    subAdministrativeArea: nil,
                    subLocality: nil
                )
            )
        ],
        urlAddresses: [
            ComposableContact.LabeledValue(label: "website", value: "https://johndoe.com")
        ],
        contactRelations: [
            ComposableContact.LabeledValue(
                label: "spouse",
                value: ComposableContact.ContactRelation(name: "Jane Doe")
            )
        ],
        socialProfiles: [
            ComposableContact.LabeledValue(
                label: "Twitter",
                value: ComposableContact.SocialProfile(
                    urlString: "https://twitter.com/johndoe",
                    username: "johndoe",
                    userIdentifier: nil,
                    service: "Twitter"
                )
            )
        ],
        instantMessageAddresses: [
            ComposableContact.LabeledValue(
                label: "Skype",
                value: ComposableContact.InstantMessageAddress(
                    username: "john.doe",
                    service: "Skype"
                )
            )
        ],
        dates: [
            ComposableContact.LabeledValue(
                label: "anniversary",
                value: DateComponents(year: 2010, month: 9, day: 25)
            )
        ]
    )

    public static let janeDoe = ComposableContact(
        identifier: "jane-doe-identifier",
        contactType: .person,
        namePrefix: "Ms.",
        givenName: "Jane",
        middleName: "B.",
        familyName: "Doe",
        previousFamilyName: "Smith",
        nameSuffix: nil,
        nickname: "Janie",
        organizationName: "Smith & Co.",
        departmentName: "Marketing",
        jobTitle: "Marketing Manager",
        phoneticGivenName: nil,
        phoneticMiddleName: nil,
        phoneticFamilyName: nil,
        phoneticOrganizationName: nil,
        birthday: DateComponents(year: 1987, month: 8, day: 20),
        nonGregorianBirthday: nil,
        note: "College friend.",
        imageData: nil,
        thumbnailImageData: nil,
        imageDataAvailable: false,
        phoneNumbers: [
            ComposableContact.LabeledValue(
                label: "mobile",
                value: ComposableContact.PhoneNumber(stringValue: "555-234-5678")
            )
        ],
        emailAddresses: [
            ComposableContact.LabeledValue(label: "personal", value: "jane.doe@example.com")
        ],
        postalAddresses: [
            ComposableContact.LabeledValue(
                label: "home",
                value: ComposableContact.PostalAddress(
                    street: "456 Elm St",
                    city: "Othertown",
                    state: "NY",
                    postalCode: "67890",
                    country: "USA",
                    isoCountryCode: "US",
                    subAdministrativeArea: nil,
                    subLocality: nil
                )
            )
        ],
        urlAddresses: [
            ComposableContact.LabeledValue(label: "LinkedIn", value: "https://linkedin.com/in/janedoe")
        ],
        contactRelations: [
            ComposableContact.LabeledValue(
                label: "spouse",
                value: ComposableContact.ContactRelation(name: "John Doe")
            )
        ],
        socialProfiles: [
            ComposableContact.LabeledValue(
                label: "Facebook",
                value: ComposableContact.SocialProfile(
                    urlString: "https://facebook.com/jane.doe",
                    username: "jane.doe",
                    userIdentifier: nil,
                    service: "Facebook"
                )
            )
        ],
        instantMessageAddresses: [
            ComposableContact.LabeledValue(
                label: "WhatsApp",
                value: ComposableContact.InstantMessageAddress(
                    username: "+15552345678",
                    service: "WhatsApp"
                )
            )
        ],
        dates: [
            ComposableContact.LabeledValue(
                label: "anniversary",
                value: DateComponents(year: 2012, month: 5, day: 15)
            )
        ]
    )
    
    public static let noop = ComposableContact(identifier: "",
                                               contactType: nil,
                                               namePrefix: nil,
                                               givenName: nil,
                                               middleName: nil,
                                               familyName: nil,
                                               previousFamilyName: nil,
                                               nameSuffix: nil,
                                               nickname: nil,
                                               organizationName: nil,
                                               departmentName: nil,
                                               jobTitle: nil,
                                               phoneticGivenName: nil,
                                               phoneticMiddleName: nil,
                                               phoneticFamilyName: nil,
                                               phoneticOrganizationName: nil,
                                               birthday: nil,
                                               nonGregorianBirthday: nil,
                                               note: nil,
                                               imageData: nil,
                                               thumbnailImageData: nil,
                                               imageDataAvailable: nil,
                                               phoneNumbers: nil,
                                               emailAddresses: nil,
                                               postalAddresses: nil,
                                               urlAddresses: nil,
                                               contactRelations: nil,
                                               socialProfiles: nil,
                                               instantMessageAddresses: nil,
                                               dates: nil)
    
}
