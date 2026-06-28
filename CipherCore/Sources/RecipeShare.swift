import Foundation

/// Encodes/decodes a `CipherRecipe` as a shareable deep link, e.g.
/// `cipherkeys://recipe?v=1&d=<base64url-json>`. Send the link (or a QR of it) to a
/// friend; tapping it imports the recipe so you both share the same scheme.
///
/// To be clear: this "shares the recipe," not a secret. Anyone with the link can
/// decode — these are classic ciphers, not encryption.
public enum RecipeShare {
    public static let scheme = "cipherkeys"
    public static let host = "recipe"

    /// Build a `cipherkeys://recipe?...` URL carrying the recipe's JSON.
    public static func url(for recipe: CipherRecipe) -> URL? {
        guard let data = try? JSONEncoder().encode(recipe) else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [
            URLQueryItem(name: "v", value: "1"),
            URLQueryItem(name: "d", value: base64URLEncode(data)),
        ]
        return components.url
    }

    /// Parse a recipe back out of a `cipherkeys://recipe?...` URL. Returns `nil` if the
    /// URL isn't ours or the payload doesn't decode.
    public static func recipe(from url: URL) -> CipherRecipe? {
        guard url.scheme == scheme, url.host == host,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let payload = items.first(where: { $0.name == "d" })?.value,
              let data = base64URLDecode(payload),
              let recipe = try? JSONDecoder().decode(CipherRecipe.self, from: data)
        else { return nil }
        return recipe
    }

    // MARK: - base64url (URL-safe, unpadded)

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        var s = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s += "=" }
        return Data(base64Encoded: s)
    }
}
