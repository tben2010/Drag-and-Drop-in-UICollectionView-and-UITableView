/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view controller that displays the albums in the photo library. Supports drag and drop of the photos in each album, as well as reordering of the albums.
*/

import UIKit

class AlbumTableViewController: UITableViewController, UITableViewDragDelegate, UITableViewDropDelegate {
    
    private var albums = PhotoLibrary.sharedInstance.albums
    
    func album(at indexPath: IndexPath) -> PhotoAlbum {
        return albums[indexPath.row]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        
        navigationItem.rightBarButtonItem = editButtonItem
        
        tableView.isSpringLoaded = true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Disable spring loading while the table view is editing.
        tableView.isSpringLoaded = !editing
    }
    
    /// Performs updates to the photo library backing store, then loads the latest album values from it.
    private func updatePhotoLibrary(_ updates: (PhotoLibrary) -> Void) {
        updates(PhotoLibrary.sharedInstance)
        reloadAlbumsFromPhotoLibrary()
    }
    
    /// Loads the latest album values from the photo library backing store.
    func reloadAlbumsFromPhotoLibrary() {
        albums = PhotoLibrary.sharedInstance.albums
    }
    
    /// Updates the visible cells to display the latest values for albums.
    func updateVisibleAlbumCells() {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return }
        for indexPath in visibleIndexPaths {
            if let cell = tableView.cellForRow(at: indexPath) as? AlbumTableViewCell {
                cell.configure(with: album(at: indexPath))
                cell.setNeedsLayout()
            }
        }
    }
    
    /// Updates the visible album cells in this table view, as well the visible photos in the selected album.
    private func updateVisibleAlbumsAndPhotos() {
        updateVisibleAlbumCells()
        
        guard let selectedIndexPath = tableView.indexPathForSelectedRow,
            let splitViewController = splitViewController,
            let detailNavigationController = splitViewController.viewControllers.count > 1 ? splitViewController.viewControllers[1] as? UINavigationController : nil,
            let photosCollectionViewController = detailNavigationController.topViewController as? PhotoCollectionViewController
            else { return }
        
        let album = self.album(at: selectedIndexPath)
        photosCollectionViewController.loadAlbum(album, from: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedIndexPath = tableView.indexPathForSelectedRow,
            let navigationController = segue.destination as? UINavigationController,
            let photosViewController = navigationController.topViewController as? PhotoCollectionViewController
            else { return }
        
        // Load the selected album in the collection view to display its photos.
        let album = self.album(at: selectedIndexPath)
        photosViewController.loadAlbum(album, from: self)
    }
    
    // MARK: UITableViewDataSource & UITableViewDelegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AlbumTableViewCell.reuseIdentifier, for: indexPath) as! AlbumTableViewCell
        cell.configure(with: album(at: indexPath))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Implement reordering by simply updating the photo library backing store.
        updatePhotoLibrary { photoLibrary in
            photoLibrary.moveAlbum(at: sourceIndexPath.row, to: destinationIndexPath.row)
        }
    }
    
    // MARK: UITableViewDragDelegate
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if tableView.isEditing {
            // User wants to reorder a row, don't return any drag items. The table view will allow a drag to begin for reordering only.
            return []
        }
        
        let dragItems = self.dragItems(forAlbumAt: indexPath)
        return dragItems
    }
    
    /// Helper method to obtain drag items for the photos inside the album at the index path.
    private func dragItems(forAlbumAt indexPath: IndexPath) -> [UIDragItem] {
        let album = self.album(at: indexPath)
        let dragItems = album.photos.map { (photo) -> UIDragItem in
            let itemProvider = photo.itemProvider
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = photo
            dragItem.previewProvider = photo.previewProvider
            return dragItem
        }
        return dragItems
    }
    
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // This is a workaround for an issue in Seed 1 where a previewProvider set before the drag session begins isn't used. This code will not be necessary in a future seed.
        for dragItem in session.items {
            if let photo = dragItem.localObject as? Photo {
                dragItem.previewProvider = photo.previewProvider
            }
        }
    }
    
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    // MARK: UITableViewDropDelegate
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.hasItemsConforming(toTypeIdentifiers: UIImage.readableTypeIdentifiersForItemProvider)
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if tableView.isEditing && tableView.hasActiveDrag {
            // The user is reordering albums in this table view.
            return UITableViewDropProposal(dropOperation: .move, intent: .insertAtDestinationIndexPath)
        } else if tableView.isEditing || tableView.hasActiveDrag {
            // Disallow drops while editing (if not reordering), or if there's already an active drag from this table view.
            return UITableViewDropProposal(operation: .forbidden)
        } else if let destinationIndexPath = destinationIndexPath, destinationIndexPath.row < albums.count {
            // Allow drops into an existing album.
            if session.localDragSession != nil {
                // If the drag began in this app, perform a move.
                return UITableViewDropProposal(dropOperation: .move, intent: .insertIntoDestinationIndexPath)
            } else {
                // Insert a new copy of the data if the drag originated in a different app.
                return UITableViewDropProposal(dropOperation: .copy, intent: .insertIntoDestinationIndexPath)
            }
        }
        
        // The destinationIndexPath is nil or does not correspond to an existing album.
        return UITableViewDropProposal(operation: .cancel)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // Since we only support dropping into existing rows, make sure the destinationIndexPath is valid.
        guard let destinationIndexPath = coordinator.destinationIndexPath, destinationIndexPath.row < albums.count else { return }
        
        switch coordinator.proposal.operation {
        case .copy:
            // Receiving items from another app.
            loadAndInsertItems(into: destinationIndexPath, with: coordinator)
        case .move:
            // Moving items from somewhere else in this app.
            moveItems(into: destinationIndexPath, with: coordinator)
        default:
            return
        }
    }
    
    /// Loads data using the item provider for each item in the drop session, inserting photos inside the album as they load.
    private func loadAndInsertItems(into destinationIndexPath: IndexPath, with coordinator: UITableViewDropCoordinator) {
        let destinationAlbum = album(at: destinationIndexPath)
        
        for item in coordinator.items {
            let dragItem = item.dragItem
            guard dragItem.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
            
            // Start loading the image for this drag item.
            dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (droppedImage, _) in
                DispatchQueue.main.async {
                    if let image = droppedImage as? UIImage {
                        // The image loaded successfully, update the photo library backing store to insert the new photo.
                        let photo = Photo(image: image)
                        self.updatePhotoLibrary { photoLibrary in
                            photoLibrary.add(photo, to: destinationAlbum)
                        }
                        self.updateVisibleAlbumsAndPhotos()
                    }
                }
            }
            
            // Animate the drag item into the cell for the album.
            if let cell = tableView.cellForRow(at: destinationIndexPath) as? AlbumTableViewCell {
                let rect = cell.rectForAlbumThumbnail ?? CGRect(origin: cell.contentView.center, size: .zero)
                coordinator.drop(dragItem, intoRowAt: destinationIndexPath, rect: rect)
            }
        }
    }
    
    /// Moves one or more photos from an album into another album.
    private func moveItems(into destinationIndexPath: IndexPath, with coordinator: UITableViewDropCoordinator) {
        let destinationAlbum = album(at: destinationIndexPath)
        
        for item in coordinator.items {
            let dragItem = item.dragItem
            // Use the localObject of the drag item to get the photo synchronously without needing to use the item provider.
            guard let photo = dragItem.localObject as? Photo else { continue }
            
            // Update the photo library backing store to move the photo.
            updatePhotoLibrary { photoLibrary in
                photoLibrary.movePhoto(photo, to: destinationAlbum)
            }
            
            // Animate the drag item into the cell for the album.
            if let cell = tableView.cellForRow(at: destinationIndexPath) as? AlbumTableViewCell {
                let rect = cell.rectForAlbumThumbnail ?? CGRect(origin: cell.contentView.center, size: .zero)
                coordinator.drop(dragItem, intoRowAt: destinationIndexPath, rect: rect)
            }
        }
        
        updateVisibleAlbumsAndPhotos()
    }
    
}
