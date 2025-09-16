import Foundation
import CoreGraphics

enum ToleranceLevel: String, CaseIterable {
    case medium // fixed band (you removed difficulty picker)

    var band: CGFloat {
        switch self {
        case .medium: return 16
        }
    }
    var label: String { "Med" }
}
