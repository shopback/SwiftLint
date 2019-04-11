import Foundation
import SourceKittenFramework

public struct ImageLiteralsNoBundleRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {
    }

    public static let description = RuleDescription(
        identifier: "image_literal_no_bundle",
        name: "Image Literals Have No Bundle",
        description: "Image literals are forbidden due to lack of bundle specification."
            + "You have to specify a bundle when using an image asset.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "let image = UIImage(named: \"foo\", in: ModuleConfiguration.shared.chatBundle,"
                + "compatibleWith: <whatever>)"
        ],
        triggeringExamples: ["", ".init"].flatMap { (_: String) -> [String] in
            [
                "let image = ↓#imageLiteral(resourceName: \"image.jpg\")"
            ]
        }
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let offset = dictionary.offset,
              let length = dictionary.length,
              kind == .objectLiteral,
              let value = file.contents.bridge().substringWithByteRange(start: offset, length: length),
            value.contains("image") else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
