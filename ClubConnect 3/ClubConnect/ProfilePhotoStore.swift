import UIKit

enum ProfilePhotoStore {
    static func fileURL() throws -> URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ClubConnect.Photo", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "The Documents folder is unavailable."])
        }
        return documents.appendingPathComponent("profile-photo.jpg")
    }

    static func load() -> UIImage? {
        guard let url = try? fileURL() else { return nil }
        // A missing file on first launch is normal; the storyboard placeholder remains.
        return UIImage(contentsOfFile: url.path)
    }

    static func save(_ image: UIImage) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ClubConnect.Photo", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "The selected photo could not be converted to JPEG."])
        }
        let url = try fileURL()
        // Atomic replacement keeps the previous photo intact if writing fails.
        try data.write(to: url, options: .atomic)
        return url
    }
}
