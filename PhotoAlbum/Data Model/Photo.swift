/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model object that represents a photo.
*/

import UIKit

struct Photo {
    let identifier = UUID()
    let image: UIImage
    let thumbnail: UIImage
    
    init(image: UIImage) {
        self.image = image
        thumbnail = generateThumbnail(for: image, with: CGSize(width: 50, height: 50))
    }
}

extension Photo: Equatable {
    static func ==(lhs: Photo, rhs: Photo) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

/// Drag and Drop functionality
extension Photo {
    
    /// Rreturns an item provider that can load the image for this photo.
    var itemProvider: NSItemProvider {
        return NSItemProvider(object: image)
    }
    
    /// Returns a closure that will generate a drag preview for this photo.
    var previewProvider: () -> UIDragPreview {
        return {
            let imageView = UIImageView(image: self.image)
            imageView.bounds.size = CGSize(width: 200, height: 200)
            imageView.frame = imageView.contentClippingRect
            return UIDragPreview(view: imageView)
        }
    }
    
}

/// Generates and returns a thumbnail for the image using scale aspect fill.
private func generateThumbnail(for image: UIImage, with thumbnailSize: CGSize) -> UIImage {
    let imageSize = image.size
    
    let widthRatio = thumbnailSize.width / imageSize.width
    let heightRatio = thumbnailSize.height / imageSize.height
    let scaleFactor = widthRatio > heightRatio ? widthRatio : heightRatio
    
    let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
    let thumbnail = renderer.image { _ in
        let size = CGSize(width: imageSize.width * scaleFactor, height: imageSize.height * scaleFactor)
        let x = (thumbnailSize.width - size.width) / 2.0
        let y = (thumbnailSize.height - size.height) / 2.0
        image.draw(in: CGRect(origin: CGPoint(x: x, y: y), size: size))
    }
    return thumbnail
}
