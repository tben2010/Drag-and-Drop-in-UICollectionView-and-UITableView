/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extension on UIImageView to compute a clipping rect for an image displayed using the scale aspect fit content mode.
*/

import UIKit

extension UIImageView {
    
    /// Returns a rect that can be applied to the image view to clip to the image, assuming a scale aspect fit content mode.
    var contentClippingRect: CGRect {
        guard let image = image, contentMode == .scaleAspectFit else { return bounds }
        
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        guard imageWidth > 0 && imageHeight > 0 else { return bounds }
        
        let scale: CGFloat
        if imageWidth > imageHeight {
            scale = bounds.size.width / imageWidth
        } else {
            scale = bounds.size.height / imageHeight
        }
        
        let clippingSize = CGSize(width: imageWidth * scale, height: imageHeight * scale)
        let x = (bounds.size.width - clippingSize.width) / 2.0
        let y = (bounds.size.height - clippingSize.height) / 2.0
        
        return CGRect(origin: CGPoint(x: x, y: y), size: clippingSize)
    }
    
}
