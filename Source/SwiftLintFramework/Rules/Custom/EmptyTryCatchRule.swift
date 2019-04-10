import Foundation
import SourceKittenFramework

public struct EmptyTryCatchRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let regularExpression = "catch[^\\{\\}]*\\{\\s*\\}"

    public static let description = RuleDescription(
            identifier: "empty_try_catch",
            name: "Empty Try Catch",
            description: "Catch closure in a try-catch statement should at least log an error.",
            kind: .idiomatic,
            minSwiftVersion: .fourDotTwo
    )

    // MARK: - ASTRule

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            return StyleViolation(ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: $0.location),
                    reason: configuration.consoleDescription)
        }
    }

    fileprivate func violationRanges(in file: File) -> [NSRange] {
        return file.match(pattern: type(of: self).regularExpression,
                with: [.keyword])
    }
}

