import Foundation
import SwiftData

// Ideally this would be a SwiftData model if we want persistence, 
// but for now I'll make it a standard struct/class structure for the view 
// and we can adhere to the existing app architecture.
// Given the existing app uses SwiftData (seen in NEW5App.swift), let's make it a Model.

@Model
final class UserProfile {
    var firstName: String
    var lastName: String
    var age: Int
    var weight: Double // in kg or lbs, let's assume kg for now or add unit
    var diabetesType: String // Type 1, Type 2, Gestational, Other
    var usesInsulin: Bool
    var takesMedication: Bool
    var targetBloodSugarLow: Int // e.g. 70
    var targetBloodSugarHigh: Int // e.g. 140
    var usesCGM: Bool
    var profileImageData: Data? // For the picture
    
    // Minimalist Redesign Fields
    var dietaryPreferences: String // e.g. "Vegan", "Low Carb"
    var isTrackingBloodSugar: Bool // Toggle for diabetic/tracking
    
    init(firstName: String = "", 
         lastName: String = "", 
         age: Int = 30, 
         weight: Double = 70.0, 
         diabetesType: String = "Type 1", 
         usesInsulin: Bool = false, 
         takesMedication: Bool = false, 
         targetBloodSugarLow: Int = 70, 
         targetBloodSugarHigh: Int = 180, 
         usesCGM: Bool = false,
         profileImageData: Data? = nil,
         dietaryPreferences: String = "",
         isTrackingBloodSugar: Bool = true) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.weight = weight
        self.diabetesType = diabetesType
        self.usesInsulin = usesInsulin
        self.takesMedication = takesMedication
        self.targetBloodSugarLow = targetBloodSugarLow
        self.targetBloodSugarHigh = targetBloodSugarHigh
        self.usesCGM = usesCGM
        self.profileImageData = profileImageData
        self.dietaryPreferences = dietaryPreferences
        self.isTrackingBloodSugar = isTrackingBloodSugar
    }
}

enum DiabetesType: String, CaseIterable, Identifiable {
    case type1 = "Type 1"
    case type2 = "Type 2"
    case gestational = "Gestational"
    case other = "Other"
    
    var id: String { self.rawValue }
}
