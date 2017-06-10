/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A collection view controller that displays the photos in a photo album. Supports drag and drop and reordering of photos in the album.
*/

import UIKit

class PhotoCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    private weak var albumTableViewController: AlbumTableViewController?
    
    private var album: PhotoAlbum? {
        didSet {
            title = album?.title
        }
    }
    
    private func photo(at indexPath: IndexPath) -> Photo {
        return album!.photos[indexPath.item]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        collectionView?.dragDelegate = self
        collectionView?.dropDelegate = self
        
        updateRightBarButtonItem()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopInsertions()
    }
    
    private var isPerformingAutomaticInsertions = false
    
    private func updateRightBarButtonItem() {
        let startInsertionsBarButtonItem = UIBarButtonItem(title: "Start Insertions", style: .plain, target: self, action: #selector(startInsertions))
        let stopInsertionsBarButtonItem = UIBarButtonItem(title: "Stop Insertions", style: .done, target: self, action: #selector(stopInsertions))
        navigationItem.rightBarButtonItem = isPerformingAutomaticInsertions ? stopInsertionsBarButtonItem : startInsertionsBarButtonItem
    }
    
    @objc
    private func startInsertions() {
        guard let album = album else { return }
        PhotoLibrary.sharedInstance.startAutomaticInsertions(into: album, photoCollectionViewController: self)
        isPerformingAutomaticInsertions = true
        updateRightBarButtonItem()
    }
    
    @objc
    private func stopInsertions() {
        PhotoLibrary.sharedInstance.stopAutomaticInsertions()
        isPerformingAutomaticInsertions = false
        updateRightBarButtonItem()
    }
    
    func loadAlbum(_ album: PhotoAlbum, from albumTableViewController: AlbumTableViewController) {
        self.album = album
        self.albumTableViewController = albumTableViewController
        if albumBeforeDrag == nil {
            collectionView?.reloadData()
        }
    }
    
    /// Performs updates to the photo library backing store, then loads the latest album & photo values from it.
    private func updatePhotoLibrary(updates: (PhotoLibrary) -> Void) {
        updates(PhotoLibrary.sharedInstance)
        reloadAlbumFromPhotoLibrary()
    }
    
    /// Loads the latest album & photo values from the photo library backing store.
    private func reloadAlbumFromPhotoLibrary() {
        if let albumIdentifier = album?.identifier {
            album = PhotoLibrary.sharedInstance.album(for: albumIdentifier)
        }
        albumTableViewController?.reloadAlbumsFromPhotoLibrary()
        albumTableViewController?.updateVisibleAlbumCells()
    }
    
    /// Called when an photo has been automatically inserted into the album this collection view is displaying.
    func insertedItem(at index: Int) {
        collectionView?.performBatchUpdates({
            self.reloadAlbumFromPhotoLibrary()
            self.collectionView?.insertItems(at: [IndexPath(item: index, section: 0)])
        })
    }
    
    // MARK: UICollectionViewDataSource & UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let album = album else { return 0 }
        return album.photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        cell.configure(with: photo(at: indexPath))
        return cell
    }

    // MARK: UICollectionViewDragDelegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = self.dragItem(forPhotoAt: indexPath)
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        let dragItem = self.dragItem(forPhotoAt: indexPath)
        return [dragItem]
    }
    
    /// Helper method to obtain a drag item for the photo at the index path.
    private func dragItem(forPhotoAt indexPath: IndexPath) -> UIDragItem {
        let photo = self.photo(at: indexPath)
        let itemProvider = photo.itemProvider
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = photo
        return dragItem
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else { return nil }
        let previewParameters = UIDragPreviewParameters()
        previewParameters.visiblePath = UIBezierPath(rect: cell.clippingRectForPhoto)
        return previewParameters
    }
    
    /// Stores the album state when the drag begins.
    private var albumBeforeDrag: PhotoAlbum?
    
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        albumBeforeDrag = album
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        reloadAlbumFromPhotoLibrary()
        deleteItems(forPhotosMovedFrom: collectionView)
        albumBeforeDrag = nil
    }
    
    /// Compares the album state before & after the drag to delete items in the collection view that represent photos moved elsewhere.
    private func deleteItems(forPhotosMovedFrom collectionView: UICollectionView) {
        guard let albumBeforeDrag = albumBeforeDrag, let albumAfterDrag = album else { return }
        
        var indexPathsToDelete = [IndexPath]()
        for (index, photo) in albumBeforeDrag.photos.enumerated() {
            if !albumAfterDrag.photos.contains(photo) {
                indexPathsToDelete.append(IndexPath(item: index, section: 0))
            }
        }
        if !indexPathsToDelete.isEmpty {
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: indexPathsToDelete)
            })
        }
    }
    
    // MARK: UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        guard album != nil else { return false }
        return session.hasItemsConforming(toTypeIdentifiers: UIImage.readableTypeIdentifiersForItemProvider)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(dropOperation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(dropOperation: .copy, intent: .insertAtDestinationIndexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard album != nil else { return }
        
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        
        switch coordinator.proposal.operation {
        case .copy:
            // Receiving items from another app.
            loadAndInsertItems(at: destinationIndexPath, with: coordinator)
        case .move:
            let items = coordinator.items
            if items.contains(where: { $0.sourceIndexPath != nil }) {
                if items.count == 1, let item = items.first {
                    // Reordering a single item from this collection view.
                    reorder(item, to: destinationIndexPath, with: coordinator)
                }
            } else {
                // Moving items from somewhere else in this app.
                moveItems(to: destinationIndexPath, with: coordinator)
            }
        default: return
        }
    }
    
    /// Loads data using the item provider and inserts a new item in the collection view for each item in the drop session, using placeholders while the data loads asynchronously.
    private func loadAndInsertItems(at destinationIndexPath: IndexPath, with coordinator: UICollectionViewDropCoordinator) {
        guard let album = album else { return }
        
        for item in coordinator.items {
            let dragItem = item.dragItem
            guard dragItem.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
            
            var placeholderContext: UICollectionViewDropPlaceholderContext? = nil
            
            // Start loading the image for this drag item.
            let progress = dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (droppedImage, _) in
                DispatchQueue.main.async {
                    if let image = droppedImage as? UIImage {
                        // The image loaded successfully, commit the insertion to exchange the placeholder for the final cell.
                        placeholderContext?.commitInsertion { insertionIndexPath in
                            // Update the photo library backing store to insert the new photo, using the insertionIndexPath passed into the closure.
                            let photo = Photo(image: image)
                            let insertionIndex = insertionIndexPath.item
                            self.updatePhotoLibrary { photoLibrary in
                                photoLibrary.insert(photo, into: album, at: insertionIndex)
                            }
                        }
                    } else {
                        // The data transfer for this item was canceled or failed, delete the placeholder.
                        placeholderContext?.deletePlaceholder()
                    }
                }
            }
            
            // Insert and animate to a placeholder for this item, configuring the placeholder cell to display the progress of the data transfer for this item.
            placeholderContext = coordinator.drop(dragItem, toPlaceholderInsertedAt: destinationIndexPath, withReuseIdentifier: PhotoPlaceholderCollectionViewCell.identifier) { cell in
                guard let placeholderCell = cell as? PhotoPlaceholderCollectionViewCell else { return }
                placeholderCell.configure(with: progress)
            }
        }
        
        // Disable the system progress indicator as we are displaying the progress of drag items in the placeholder cells.
        coordinator.session.progressIndicatorStyle = .none
    }
    
    /// Moves an item (photo) in this collection view from one index path to another index path.
    private func reorder(_ item: UICollectionViewDropItem, to destinationIndexPath: IndexPath, with coordinator: UICollectionViewDropCoordinator) {
        guard let collectionView = collectionView, let album = album, let sourceIndexPath = item.sourceIndexPath else { return }
        
        // Perform batch updates to update the photo library backing store and perform the delete & insert on the collection view.
        collectionView.performBatchUpdates({
            self.updatePhotoLibrary { photoLibrary in
                photoLibrary.movePhoto(in: album, from: sourceIndexPath.item, to: destinationIndexPath.item)
            }
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
        })
        
        // Animate the drag item to the newly inserted item in the collection view.
        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
    }
    
    /// Moves one or more photos from a different album into this album by inserting items into this collection view.
    private func moveItems(to destinationIndexPath: IndexPath, with coordinator: UICollectionViewDropCoordinator) {
        guard let collectionView = collectionView, let album = album else { return }
        
        var destinationIndex = destinationIndexPath.item
        for item in coordinator.items {
            // Use the localObject of the drag item to get the photo synchronously without needing to use the item provider.
            guard let photo = item.dragItem.localObject as? Photo, !album.contains(photo: photo) else { continue }
            
            let insertionIndexPath = IndexPath(item: destinationIndex, section: 0)
            
            // Perform batch updates to update the photo library backing store and perform the insert on the collection view.
            collectionView.performBatchUpdates({
                self.updatePhotoLibrary { photoLibrary in
                    photoLibrary.movePhoto(photo, to: album, index: destinationIndex)
                }
                collectionView.insertItems(at: [insertionIndexPath])
            })
            
            // Animate the drag item to the newly inserted item in the collection view.
            coordinator.drop(item.dragItem, toItemAt: insertionIndexPath)
            
            destinationIndex += 1
        }
    }
    
}
