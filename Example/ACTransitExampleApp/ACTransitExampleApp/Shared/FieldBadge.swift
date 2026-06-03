import SwiftUI

struct FieldBadge: View {
    enum Requirement {
        case required
        case optional
    }

    let requirement: Requirement

    var body: some View {
        Text(requirement == .required ? "required" : "optional")
            .font(.caption2)
            .foregroundStyle(requirement == .required ? Color.red : Color.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(requirement == .required ? Color.red.opacity(0.15) : Color(.quaternarySystemFill), in: Capsule())
    }
}
