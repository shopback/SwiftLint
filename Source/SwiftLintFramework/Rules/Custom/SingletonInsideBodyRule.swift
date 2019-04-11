import Foundation
import SourceKittenFramework

public struct SingletonInsideBodyRule: OptInRule, ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {
    }

    public static let description = RuleDescription(
        identifier: "singleton_inside_body",
        name: "Singleton Inside Method Body",
        description: "Singletons should not be called directly by using .shared"
            + "inside method body but should be injected first.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotTwo
    )

    // MARK: - ASTRule

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            case let contentsNSString = file.contents.bridge()
            else {
                return []
        }
        let body = contentsNSString.substringWithByteRange(start: bodyOffset, length: bodyLength)
        guard let occurrence = body?.range(of: ".shared") else {
            return []
        }
        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location( file: file,
                                                   byteOffset: bodyOffset + occurrence.lowerBound.encodedOffset),
                               reason: "Singletons should not be called directly by using .shared inside method body.")]
    }
}
