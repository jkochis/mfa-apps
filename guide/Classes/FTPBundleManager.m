//
//  FTPBundleManager.m
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "FTPBundleManager.h"

#import <sys/dirent.h>

#import "FTPBundleManagerDirectory.h"
#import "FTPBundleManagerFile.h"

@interface FTPBundleManager (PrivateMethods)

- (void)retrieveNextDirectory;
- (void)retrieveNextFile;

@end

@implementation FTPBundleManager

@synthesize delegate, ftpRequest, fileManager, bundleName, bundleFiles, bundleDirectories, currentBundlePath;

#pragma mark -
#pragma mark Accessors

- (FTPRequest *)ftpRequest
{
	// lazy initializer
	if (!ftpRequest) {
		ftpRequest = [[FTPRequest alloc] initWithUserName:FTP_USERNAME andPassword:FTP_PASSWORD];
		[ftpRequest setDelegate:self];
	}
	return ftpRequest;
}

- (NSFileManager *)fileManager
{
	// lazy initializer
	if (!fileManager) {
		fileManager = [[NSFileManager alloc] init];
	}
	return fileManager;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
	[ftpRequest release];
	[fileManager release];
	[bundleName release];
	[bundleDirectories release];
	[bundleFiles release];
	[currentBundlePath release];
	[super dealloc];
}

#pragma mark -
#pragma mark Bundles

- (void)retrieveOrUpdateBundle:(NSString *)theBundleName
{	
	// init request
	[self setBundleName:theBundleName];
	[self setBundleFiles:[NSMutableArray array]];
	[self setBundleDirectories:[NSMutableArray array]];
	[self setCurrentBundlePath:@""];
	[[self ftpRequest] retrieveDirectory:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@.bundle/", FTP_ROOT, bundleName]]];
}

- (void)retrieveNextDirectory
{
	// check for remaining directories in queue
	if ([bundleDirectories count]) {
		FTPBundleManagerDirectory *subdirectory = [bundleDirectories objectAtIndex:0];
		NSString *relativePath = [NSString stringWithFormat:@"%@%@/", [subdirectory path], [subdirectory directory]];
		[self setCurrentBundlePath:relativePath];
		[[self ftpRequest] retrieveDirectory:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@.bundle/%@", FTP_ROOT, bundleName, relativePath]]];
	}
	
	// otherwise start file queue
	else {
		currentFile = 0;
		totalFiles = [bundleFiles count];
		[self retrieveNextFile];
	}
}

- (void)retrieveNextFile
{
	// if no files remain, notify delegate and quit
	if ([bundleFiles count] == 0) {
		if ([delegate respondsToSelector:@selector(bundleManagerCompletedUpdate:)]) {
			[delegate bundleManagerCompletedUpdate:self];
		}
		return;
	}
	
	// otherwise, gather information
	FTPBundleManagerFile *file = [bundleFiles objectAtIndex:0];
	NSString *relativePath = [NSString stringWithFormat:@"%@%@", [file path], [file filename]];
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [documentsPaths objectAtIndex:0];
	NSString *filePath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]];
	
	// check to see if the file already exists
	if ([[self fileManager] fileExistsAtPath:filePath]) {
		
		// if so, compare updated date to file on server and skip if newer
		NSError *error = nil;
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:&error];
		if (error) {
			NSLog(@"%@", [error localizedDescription]);
		}
		if ([[fileAttributes fileModificationDate] timeIntervalSinceDate:[file modificationDate]] >= 0) {
			[bundleFiles removeObjectAtIndex:0];
			[self retrieveNextFile];
			return;
		}
	}
	
	// if still alive, retrieve file
	currentFile++;
	[[self ftpRequest] retrieveFile:[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@.bundle/%@", FTP_ROOT, bundleName, relativePath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	if ([delegate respondsToSelector:@selector(bundleManager:didStartUpdatingFile:fileNumber:outOf:)]) {
		[delegate bundleManager:self 
		   didStartUpdatingFile:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath] 
					 fileNumber:currentFile 
						  outOf:totalFiles];
	}
}

#pragma mark -
#pragma mark FTPRequestDelegate Methods

- (void)ftpRequest:(FTPRequest *)ftpRequest didFailWithError:(NSError *)error
{
	NSLog(@"Error: %@", [error localizedDescription]);
}

- (void)ftpRequest:(FTPRequest *)ftpRequest didRetrieveDirectory:(NSArray *)directory
{
	// iterate through directory contents
	for (NSDictionary *item in directory)
	{
		// get item type
		NSNumber *resourceType = (NSNumber *)[item objectForKey:(NSString *)kCFFTPResourceType];
		
		// if item is a directory, add entry to bundleDirectories
		if ([resourceType isEqualToNumber:[NSNumber numberWithInt:DT_DIR]]) {
			FTPBundleManagerDirectory *subdirectory = [[FTPBundleManagerDirectory alloc] initWithDirectory:[item objectForKey:(NSString *)kCFFTPResourceName]
																								path:currentBundlePath];
			[bundleDirectories addObject:subdirectory];
			[subdirectory release];
		}
		
		// if item is a file, add entry to bundleFiles
		else if ([resourceType isEqualToNumber:[NSNumber numberWithInt:DT_REG]]) {
			FTPBundleManagerFile *file = [[FTPBundleManagerFile alloc] initWithFilename:[item objectForKey:(NSString *)kCFFTPResourceName]
																			 path:currentBundlePath
																			 size:[item objectForKey:(NSString *)kCFFTPResourceSize]
																 modificationDate:[item objectForKey:(NSString *)kCFFTPResourceModDate]];
			[bundleFiles addObject:file];
			[file release];
		}
	}
	
	// remove directory from queue
	if (![currentBundlePath isEqualToString:@""]) {
		[bundleDirectories removeObjectAtIndex:0];
	}
	
	// retrieve any remaining directories
	[self retrieveNextDirectory];
}

- (void)ftpRequest:(FTPRequest *)ftpRequest didRetrieveBytes:(NSInteger)bytes
{
	FTPBundleManagerFile *file = [bundleFiles objectAtIndex:0];
	if ([delegate respondsToSelector:@selector(bundleManager:didRecieveBytes:outOfTotalBytes:forFile:)]) {
		[delegate bundleManager:self didRecieveBytes:bytes outOfTotalBytes:[[file size] intValue] forFile:[NSString stringWithFormat:@"/%@.bundle/%@%@", bundleName, [file path], [file filename]]];
	}
}

- (void)ftpRequest:(FTPRequest *)ftpRequest didRetrieveFile:(NSString *)pathToFile
{
	// gather information
	FTPBundleManagerFile *file = [bundleFiles objectAtIndex:0];
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [documentsPaths objectAtIndex:0];
	NSString *localDirectory = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, [file path]]];
	NSString *localPath = [localDirectory stringByAppendingString:[file filename]];
	NSError *error = nil;
	
	// check to see if directory exists, and if not create it
	BOOL isDir;
	if (!([[self fileManager] fileExistsAtPath:localDirectory isDirectory:&isDir] && isDir)) {
		[fileManager createDirectoryAtPath:localDirectory withIntermediateDirectories:YES attributes:nil error:&error];
		if (error) {
			NSLog(@"%@", [error localizedDescription]);
		}
	}
	
	// check to see if file exists, and if so remove it
	if ([fileManager fileExistsAtPath:localPath]) {
		[fileManager removeItemAtPath:localPath error:&error];
		if (error) {
			NSLog(@"%@", [error localizedDescription]);
		}
	}
	
	// move temporary file into bundle
	[fileManager moveItemAtPath:pathToFile toPath:localPath error:&error];
	if (error) {
		NSLog(@"%ld: %@", [error localizedDescription]);
	}
	
	// send notification to delegate
	if ([delegate respondsToSelector:@selector(bundleManager:didFinishUpdatingFile:fileNumber:outOf:)]) {
		[delegate bundleManager:self 
		  didFinishUpdatingFile:[NSString stringWithFormat:@"/%@.bundle/%@%@", bundleName, [file path], [file filename]]
					 fileNumber:currentFile
						  outOf:totalFiles];
	}
	
	// remove file from queue
	[bundleFiles removeObjectAtIndex:0];
	
	// retrieve next file
	[self retrieveNextFile];
}

@end
