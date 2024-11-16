import 'dart:io';

// This script will search the specified directories for files and delete them until the target free space is reached.
// The target free space is specified in GB.
// The directories to search are specified in the directories list.
// The script will delete the oldest files first based on birth time.

void main() async {
  // Define the directories to search
  List<String> directories = ['/mnt/media/tv', '/mnt/media/movies'];

  // Define the target free space in GB
  int targetFreeSpaceGB = 100;
  int targetFreeSpace = targetFreeSpaceGB * 1024 * 1024 * 1024; // Convert to bytes

  // Get the current free space on the /mnt partition
  var dfResult = Process.runSync('df', ['-k','/mnt/media']); // -k for kilobytes
  var freeSpaceString = dfResult.stdout.split('\n')[1].split(' ')[8];
  var freeSpaceKB = int.tryParse(freeSpaceString) ?? 0;
  var currentFreeSpace = freeSpaceKB * 1024; // Convert to bytes
  print("Current free space: ${currentFreeSpace/1024/1024/1024} GB");

  // Calculate the amount of space that needs to be freed
  int spaceToFree = targetFreeSpace - currentFreeSpace;

  // Check if there's already enough free space
  if (spaceToFree <= 0) {
    print('There is already at least $targetFreeSpaceGB GB of free space available.');
    exit(0);
  }

  print('Need to free up ${spaceToFree ~/ 1024 ~/ 1024 ~/ 1024} GB.');

  // Find and delete files by birth time until enough space is freed
  int freedSpace = 0;

  List<MediaFile> mediaFiles = [];

  

  // Use a loop to process the directories
  // Iterate over each directory
  for (var dir in directories) {
    var directory = Directory(dir);
    // Check if the directory exists
    if (directory.existsSync()) {
      // Get a list of files in the directory and its subdirectories recursively
      var files = directory.listSync(recursive: true);

      //Loop over each file in files and get the birth time of the file


      // Sort the files by birth time in ascending order
      
      // Iterate over each file in the directory
      for (var file in files) {
        // Check if the file is a regular file
        if (file is File) {
          var filePath = file.path;
          var fileSize = file.lengthSync();
          var birthTime = DateTime.parse(Process.runSync('stat', [filePath]).stdout.split('\n')[7].trim().split(' ')[1]);
          mediaFiles.add(MediaFile(filePath, birthTime, fileSize));


          // var filePath = file.path;
          // // Check if the file is currently being accessed by another process
          // var lsofResult = Process.runSync('lsof', [filePath]);
          // // If the file is being accessed, skip it
          // if (lsofResult.stdout.isNotEmpty) {
          //   print('Skipping $filePath as it is currently being accessed by another process.');
          //   continue;
          // }

          // var fileSize = file.lengthSync();
          // // Attempt to delete the file
          // if (!(await file.delete()).existsSync()) {
          //   // If the file is successfully deleted, update the freed space counter
          //   freedSpace += fileSize;
          //   print('Deleted $filePath');
          // } else {
          //   print('Failed to delete $filePath');
          // }

          // // Check if enough space has been freed
          // if (freedSpace >= spaceToFree) {
          //   print('Freed enough space.');
          //   exit(0);
          // }
        }
      }
    } else {
      print('Directory $dir does not exist or is not accessible.');
    }
  }

  //Sort mediaFiles by birthTime
  mediaFiles.sort((a, b) => a.birthTime.compareTo(b.birthTime));

  // Make a shortlist of files to delete
  List<MediaFile> filesToDelete = [];

  for (var mediaFile in mediaFiles) {
    if (freedSpace >= spaceToFree) {
      break;
    }
    filesToDelete.add(mediaFile);
    freedSpace += mediaFile.size;
  }

  // Display the files to be deleted
  for (var mediaFile in filesToDelete) {
    print('Deleting ${mediaFile.path}, birth time: ${mediaFile.birthTime}, size: ${mediaFile.size}');
    await File(mediaFile.path).delete();
  }

  print('Freed ${freedSpace ~/ 1024 ~/ 1024 ~/ 1024} GB of space.');
}

class MediaFile {
  String path;
  DateTime birthTime;
  int size;

  MediaFile(this.path, this.birthTime, this.size);
}