//
//  Composa.swift
//  ComposableContacts
//
//  Created by Scott Hoge on 12/12/24.
//

import Foundation
@preconcurrency import Contacts

/// An enum representing all possible keys for accessing fields in a [CNContact](https://developer.apple.com/documentation/contacts/cncontact). They map to  the corresponding [CNKeyDescriptor](https://developer.apple.com/documentation/contacts/cnkeydescriptor) via the `keyDescriptor` variable.
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
