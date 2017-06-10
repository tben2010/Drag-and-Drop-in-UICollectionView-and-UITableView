/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A collection view cell used as a placeholder for a photo during the asynchronous data transfer of a drop session.
*/

import UIKit

class PhotoPlaceholderCollectionViewCell: UICollectionViewCell {
    static let identifier = "PhotoPlaceholderCollectionViewCell"
    
    @IBOutlet private weak var progressView: UIProgressView!
    
    /// Stores a progress that is observed using KVO to update the progress view.
    private var progress: Progress? {
        willSet(newProgress) {
            progress?.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
        }
        didSet {
            if let progress = progress {
                progressView.setProgress(Float(progress.fractionCompleted), animated: false)
                progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: [.initial, .new], context: nil)
            }
        }
    }
    
    /// Configures the cell to display the progress.
    func configure(with progress: Progress) {
        self.progress = progress
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? Progress == progress && keyPath == #keyPath(Progress.fractionCompleted) {
            if let fractionCompleted = change?[.newKey] as? Double {
                DispatchQueue.main.async {
                    // Update the progress view to display the new fractionCompleted value from the progress.
                    self.progressView.setProgress(Float(fractionCompleted), animated: true)
                }
            }
        }
    }
    
    deinit {
        progress = nil
    }
}
