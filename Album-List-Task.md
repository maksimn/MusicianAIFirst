# Album List feature.

Implement a screen with a list of music albums.

## Data

Fetch data from URL: http://maksimn.github.io/albums.json

Use previously defined `NetworkDataLoader` and its implementation.

It contains JSON array of Album objects. Album and Track data types are described below.

### Album

* `albumId` integer
* `albumName` string
* `albumYear` integer
* `albumCover` string
* `albumMedianColor` string
* `tracks` array of Track

### Track

* `trackId` integer
* `name` string
* `url` string
* `duration` string

Parse JSON to get an array of albums.

Implement caching of the downloaded data on the local device. Use SwiftData or another approach to do it.

## View

Create `AlbumListView` with the list of albums.

UI Framework: SwiftUI.

Architecture: Clean MVVM.
