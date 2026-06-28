import Foundation

/// A user-built, named pipeline of invertible steps (Tier-2 "build your own cipher").
public struct CipherRecipe: Codable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var steps: [RecipeStep]

    public init(id: UUID = UUID(), name: String, steps: [RecipeStep]) {
        self.id = id
        self.name = name
        self.steps = steps
    }
}

/// Adapts a `CipherRecipe` to the shared `Cipher` protocol so recipes are
/// interchangeable with the built-in ciphers everywhere (app, keyboard, extension).
///
/// `encode` runs the steps front-to-back; `decode` runs them back-to-front, inverting
/// each. Because every `RecipeStep` is invertible, the round-trip always holds.
public struct RecipeCipher: Cipher {
    public let recipe: CipherRecipe

    public init(_ recipe: CipherRecipe) { self.recipe = recipe }

    public var id: String { recipe.id.uuidString }
    public var name: String { recipe.name }

    public func encode(_ text: String) -> String {
        recipe.steps.reduce(text) { partial, step in step.apply(partial, decoding: false) }
    }

    public func decode(_ text: String) -> String {
        recipe.steps.reversed().reduce(text) { partial, step in step.apply(partial, decoding: true) }
    }
}
