/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The backing data store for the application that contains an array of photo albums, and methods to retrieve data from and mutate the contents of these albums.
*/

import UIKit

class PhotoLibrary {
    static let sharedInstance = PhotoLibrary()
    
    private(set) var albums = [PhotoAlbum]()
    
    // MARK: Identifier Lookups
    
    func album(for identifier: UUID) -> PhotoAlbum? {
        return albums.first(where: { photo in photo.identifier == identifier })
    }
    
    func photo(for identifier: UUID) -> Photo? {
        let album = albums.first(where: { album in
            album.photos.contains(where: { photo in photo.identifier == identifier })
        })
        return album?.photos.first(where: { photo in photo.identifier == identifier })
    }
    
    // MARK: Photo Library Mutations
    
    /// Adds a photo to the album.
    func add(_ photo: Photo, to album: PhotoAlbum) {
        guard let albumIndex = albums.index(of: album) else { return }
        
        albums[albumIndex].photos.insert(photo, at: 0)
    }
    
    /// Inserts the photo at a specific index in the album.
    func insert(_ photo: Photo, into album: PhotoAlbum, at index: Int) {
        guard let albumIndex = albums.index(of: album) else { return }
        
        albums[albumIndex].photos.insert(photo, at: index)
    }
    
    /// Moves an album from one index to another.
    func moveAlbum(at sourceIndex: Int, to destinationIndex: Int) {
        let album = albums[sourceIndex]
        albums.remove(at: sourceIndex)
        albums.insert(album, at: destinationIndex)
    }
    
    /// Moves a photo from one index to another in the album.
    func movePhoto(in album: PhotoAlbum, from sourceIndex: Int, to destinationIndex: Int) {
        guard let albumIndex = albums.index(of: album) else { return }
        
        let photo = albums[albumIndex].photos[sourceIndex]
        albums[albumIndex].photos.remove(at: sourceIndex)
        albums[albumIndex].photos.insert(photo, at: destinationIndex)
    }
    
    /// Moves a photo to a different album at a specific index in that album. Defaults to inserting at the beginning of the album if no index is specified.
    func movePhoto(_ photo: Photo, to album: PhotoAlbum, index: Int = 0) {
        guard let sourceAlbumIndex = albums.index(where: { album in album.photos.contains(photo) }),
            let indexOfPhotoInSourceAlbum = albums[sourceAlbumIndex].photos.index(of: photo),
            let destinationAlbumIndex = albums.index(of: album)
            else { return }
        
        let photo = albums[sourceAlbumIndex].photos[indexOfPhotoInSourceAlbum]
        albums[sourceAlbumIndex].photos.remove(at: indexOfPhotoInSourceAlbum)
        albums[destinationAlbumIndex].photos.insert(photo, at: index)
    }
    
    // MARK: Timed Automatic Insertions
    
    private var albumForAutomaticInsertions: PhotoAlbum?
    private var automaticInsertionTimer: Timer?
    
    /// Starts a timer that performs an automatic insertion of a photo into the album when it fires.
    func startAutomaticInsertions(into album: PhotoAlbum, photoCollectionViewController: PhotoCollectionViewController) {
        stopAutomaticInsertions()
        albumForAutomaticInsertions = album
        automaticInsertionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            guard let album = self.albumForAutomaticInsertions, let albumIndex = self.albums.index(of: album) else { return }
            let image: UIImage = #imageLiteral(resourceName: "AutomaticInsertion.png")
            let photo = Photo(image: image)
            let insertionIndex = Int(arc4random_uniform(UInt32(self.albums[albumIndex].photos.count)))
            self.albums[albumIndex].photos.insert(photo, at: insertionIndex)
            photoCollectionViewController.insertedItem(at: insertionIndex)
        })
    }
    
    /// Stops the timer that performs automatic insertions.
    func stopAutomaticInsertions() {
        albumForAutomaticInsertions = nil
        automaticInsertionTimer?.invalidate()
        automaticInsertionTimer = nil
    }
    
    // MARK: Initialization and Loading Sample Data
    
    init() {
        self.loadSampleData()
    }
    
    private func loadSampleData() {
        var albumIndex = 0
        var foundAlbum: Bool
        repeat {
            foundAlbum = false
            var photos = [Photo]()
            
            var photoIndex = 0
            var foundPhoto: Bool
            repeat {
                foundPhoto = false
                let imageName = "Album\(albumIndex)Photo\(photoIndex).jpg"
                if let image = UIImage(named: imageName) {
                    foundPhoto = true
                    let photo = Photo(image: image)
                    photos.append(photo)
                }
                photoIndex += 1
            } while foundPhoto
            
            if !photos.isEmpty {
                foundAlbum = true
                let title = "Album \(albumIndex + 1)"
                let album = PhotoAlbum(title: title, photos: photos)
                albums.append(album)
            }
            albumIndex += 1
        } while foundAlbum
    }
}
