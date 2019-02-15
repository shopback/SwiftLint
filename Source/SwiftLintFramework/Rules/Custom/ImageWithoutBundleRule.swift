import Foundation
import SourceKittenFramework

public struct ImageWithoutBundleRule: ASTRule, ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.error)

    public init() {
    }

    public static let description = RuleDescription(
            identifier: "image_bundle",
            name: "Image Without Bundle",
            description: "You have to specify a bundle when using an image asset.",
            kind: .idiomatic,
            nonTriggeringExamples: [
                "let image = UIImage(named: \"foo\", in: ModuleConfiguration.shared.chatBundle, compatibleWith: <whatever>)"
            ],
            triggeringExamples: ["", ".init"].flatMap { (method: String) -> [String] in
                [
                    "let image = ↓UIImage\(method)(named: \"foo\")",
                    "let image = ↓UIImage\(method)(named: \"foo\", in: nil, compatibleWith: <whatever>)"
                ]
            }
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call,
              let offset = dictionary.offset,
              isImageNamedInit(dictionary: dictionary, file: file),
              !hasNonNilBundle(dictionary: dictionary, file: file) else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isImageNamedInit(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let name = dictionary.name,
              inits(forClasses: ["UIImage", "NSImage"]).contains(name),
              case let arguments = dictionary.enclosedArguments,
              arguments.compactMap({ $0.name }).contains("named") else {
            return false
        }

        return true
    }

    private func hasNonNilBundle(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let name = dictionary.name,
              inits(forClasses: ["UIImage", "NSImage"]).contains(name),
              case let arguments = dictionary.enclosedArguments else {
            return false
        }
        guard arguments.compactMap({ $0.name }).contains("in"),
              let argument = arguments.first(where: { $0.name == "in"}),
              !isArgumentNil(argument, file: file) else {
            return false
        }

        return true
    }

    private func inits(forClasses names: [String]) -> [String] {
        return names.flatMap { name in
            [
                name,
                name + ".init"
            ]
        }
    }

    private func isArgumentNil(_ argument: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let offset = argument.bodyOffset, let length = argument.bodyLength else {
            return false
        }

        let value = file.contents.bridge().substringWithByteRange(start: offset, length: length) ?? ""
        return value == "nil" || value == "Bundle.main"
    }

    private func kinds(forArgument argument: [String: SourceKitRepresentable], file: File) -> Set<SyntaxKind> {
        guard let offset = argument.bodyOffset, let length = argument.bodyLength else {
            return []
        }

        let range = NSRange(location: offset, length: length)
        return Set(file.syntaxMap.kinds(inByteRange: range))
    }
}