import SwiftUI

// MARK: - Category

enum ElementCategory: String, CaseIterable, Codable {
    case alkaliMetal     = "Alkali metal"
    case alkalineEarth   = "Alkaline earth"
    case transitionMetal = "Transition metal"
    case otherMetal      = "Other metal"
    case metalloid       = "Metalloid"
    case nonmetal        = "Nonmetal"
    case halogen         = "Halogen"
    case nobleGas        = "Noble gas"
    case rareEarth       = "Rare earth"
    case actinide        = "Actinide"

    /// Cell / badge colour on the table.
    var colour: Color {
        switch self {
        case .alkaliMetal:     return Color(hex: 0xFF6B4A)
        case .alkalineEarth:   return Color(hex: 0xFFB03A)
        case .transitionMetal: return Color(hex: 0x4D8DFF)
        case .otherMetal:      return Color(hex: 0x6FD3E0)
        case .metalloid:       return Color(hex: 0x9C8BFF)
        case .nonmetal:        return Color(hex: 0x3FD97F)
        case .halogen:         return Color(hex: 0xE7DE3F)
        case .nobleGas:        return Color(hex: 0xFF5CC8)
        case .rareEarth:       return Color(hex: 0x00C4A7)
        case .actinide:        return Color(hex: 0xC77BFF)
        }
    }

    /// Is this a metal for art purposes (shiny chunk vs matte lump)?
    var isMetallic: Bool {
        switch self {
        case .alkaliMetal, .alkalineEarth, .transitionMetal,
             .otherMetal, .rareEarth, .actinide:
            return true
        case .metalloid:
            return true
        case .nonmetal, .halogen, .nobleGas:
            return false
        }
    }
}

// MARK: - Phase at room temperature

enum Phase: String, Codable {
    case solid, liquid, gas

    var label: String {
        switch self {
        case .solid:  return "Solid"
        case .liquid: return "Liquid"
        case .gas:    return "Gas"
        }
    }
}

// MARK: - How the sample gets drawn

/// The shape a real sample tends to come in. Element collections are full of
/// bars, pellets, powders and crystals, and that variety is what makes the
/// picture round winnable.
enum SampleForm {
    case chunk      // irregular lump
    case ingot      // cast bar
    case pellets    // little beads
    case powder     // mound of dust
    case crystal    // faceted cluster
    case wire       // coil of wire or ribbon
    case pool       // liquid
    case cloud      // gas
    case tube       // noble gas discharge tube
    case shard      // radioactive, glowing

    /// What the drawing looks like, for VoiceOver. Describes appearance only,
    /// never the element, so the picture round stays winnable without handing
    /// over the answer.
    var spoken: String {
        switch self {
        case .chunk:   return "an irregular lump"
        case .ingot:   return "a cast bar"
        case .pellets: return "a scatter of little beads"
        case .powder:  return "a heap of powder"
        case .crystal: return "a cluster of faceted crystals"
        case .wire:    return "a coil of wire"
        case .pool:    return "droplets and a puddle"
        case .cloud:   return "a drifting cloud"
        case .tube:    return "a glowing discharge tube"
        case .shard:   return "a glowing shard with a pulsing ring"
        }
    }
}

// MARK: - Element

struct ChemElement: Identifiable, Hashable {
    let z: Int
    let symbol: String
    let name: String
    let category: ElementCategory
    let phase: Phase
    let fact: String
    private let tintHex: UInt?

    init(_ z: Int, _ symbol: String, _ name: String,
         _ category: ElementCategory, _ phase: Phase,
         tint: UInt? = nil, _ fact: String) {
        self.z = z
        self.symbol = symbol
        self.name = name
        self.category = category
        self.phase = phase
        self.tintHex = tint
        self.fact = fact
    }

    var id: Int { z }

    /// Base colour the sample art is painted in.
    var tint: Color {
        if let tintHex { return Color(hex: tintHex) }
        switch category {
        case .alkaliMetal, .alkalineEarth: return Color(hex: 0xD9DEE6)
        case .transitionMetal:             return Color(hex: 0xB9C2CE)
        case .otherMetal:                  return Color(hex: 0xC6CCD6)
        case .rareEarth, .actinide:        return Color(hex: 0xADB6C4)
        case .metalloid:                   return Color(hex: 0x8E96A6)
        case .nonmetal:                    return Color(hex: 0x7FE3A8)
        case .halogen:                     return Color(hex: 0xE3DC72)
        case .nobleGas:                    return Color(hex: 0xFF7ED0)
        }
    }

    var isRadioactive: Bool {
        z == 43 || z == 61 || z >= 84
    }

    var form: SampleForm {
        if category == .nobleGas { return .tube }
        if phase == .gas { return .cloud }
        if phase == .liquid { return .pool }
        if isRadioactive { return .shard }
        if let known = Self.knownForms[z] { return known }

        // Alkali metals are soft waxy lumps kept under oil, never bars or wire.
        if category == .alkaliMetal { return .chunk }

        let solidForms: [SampleForm]
        switch category {
        case .metalloid:
            solidForms = [.chunk, .crystal, .powder]
        case .nonmetal, .halogen:
            solidForms = [.chunk, .powder, .crystal]
        default:
            solidForms = [.chunk, .ingot, .pellets, .powder, .crystal, .wire]
        }
        return solidForms[z % solidForms.count]
    }

    /// How these ones actually turn up: copper as wire, gold as a bar, sulfur
    /// as yellow powder, bismuth as those stepped rainbow crystals.
    private static let knownForms: [Int: SampleForm] = [
        3: .chunk, 6: .powder, 12: .wire, 13: .ingot, 14: .crystal,
        15: .chunk, 16: .powder, 19: .chunk, 20: .pellets, 22: .ingot,
        24: .crystal, 26: .chunk, 28: .pellets, 29: .wire, 30: .pellets,
        33: .chunk, 34: .powder, 47: .ingot, 50: .ingot, 53: .crystal,
        74: .ingot, 78: .ingot, 79: .ingot, 82: .chunk, 83: .crystal
    ]

    /// Shiny (metal sheen) or matte (rock, powder)?
    var isShiny: Bool { category.isMetallic && category != .metalloid }

    /// VoiceOver description of the drawn sample. Appearance only: form, sheen
    /// and state, which is exactly the information the picture gives a sighted
    /// child. Naming the element would give away the answer.
    var artDescription: String {
        let sheen = isShiny ? "shiny " : ""
        return "\(sheen)\(form.spoken). \(phase.label) at room temperature."
    }

    /// Column (1...18) on the standard table. Lanthanides and actinides sit in
    /// their own two rows underneath.
    var column: Int {
        switch z {
        case 1: return 1
        case 2: return 18
        case 3...4, 11...12: return z <= 4 ? z - 2 : z - 10
        case 5...10: return z + 8
        case 13...18: return z
        case 19...36: return z - 18
        case 37...54: return z - 36
        case 55...56: return z - 54
        case 57...71: return z - 54            // rare earth row, cols 3...17
        case 72...86: return z - 68
        case 87...88: return z - 86
        case 89...103: return z - 86           // actinide row, cols 3...17
        default: return z - 100
        }
    }

    /// Row 1...7 for the main block, 9 for rare earths, 10 for actinides.
    var row: Int {
        switch z {
        case 1...2: return 1
        case 3...10: return 2
        case 11...18: return 3
        case 19...36: return 4
        case 37...54: return 5
        case 57...71: return 9
        case 55...86: return 6
        case 89...103: return 10
        default: return 7
        }
    }
}
