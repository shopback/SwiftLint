import Foundation
import SourceKittenFramework

public struct MethodWithClosure: OptInRule, ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {
    }

    public static let description = RuleDescription(
            identifier: "method_with_closure",
            name: "Method With Closure",
            description: "If a method declaration contains non-optional closure it has to be executed at least once inside methods body",
            kind: .idiomatic,
            minSwiftVersion: .fourDotTwo
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
              let bodyOffset = dictionary.bodyOffset,
              let bodyLength = dictionary.bodyLength,
              !dictionary.enclosedSwiftAttributes.contains(.override),
              case let contentsNSString = file.contents.bridge(),
              let body = contentsNSString.substringWithByteRange(start: bodyOffset, length: bodyLength) else {
            return []
        }

        let isClosure = {
            self.isClosureParameter(dictionary: $0)
        }
        let params = dictionary.enclosedVarParameters.filter(isClosure).filter { param in
            guard let paramOffset = param.offset else {
                return false
            }

            return paramOffset < bodyOffset
        }

        guard !params.isEmpty else {
            return []
        }

        var violations = [StyleViolation]()
        for param in params {
            guard let completionName = param.name else {
                return []
            }

            if !body.contains(completionName) {
                let violation = StyleViolation(
                        ruleDescription: type(of: self).description,
                        severity: configuration.severity,
                        location: Location(file: file, byteOffset: bodyOffset))
                violations.append(violation)
            }
        }

        return violations
    }

    private func isClosureParameter(dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard let typeName = dictionary.typeName else {
            return false
        }

        return typeName.contains("->") || typeName.contains("@escaping")
    }
}
