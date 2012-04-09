//
//  HTTPBundleManager.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/11/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "HTTPBundleManager.h"

#import "BaseStop.h"
#import "StopFactory.h"
#import "TourController.h"

@interface HTTPBundleManager (PrivateMethods)

- (void)buildFileList:(xmlDocPtr)tourDoc;
- (BOOL)writeTourML:(xmlDocPtr)tourDoc error:(NSError **)error;
- (BOOL)checkOrCreateDirectory:(NSString *)directory error:(NSError **)error;
- (void)retrieveNextFile;
- (void)cleanupLocalFiles;

@end

@implementation HTTPBundleManager

@synthesize delegate, httpRequest, fileManager, documentsDirectory, bundleName, bundleUrl, bundleFiles, updatableFiles, currentModificationDate;

- (HTTPRequest *)httpRequest
{
	if (httpRequest == nil) {
		httpRequest = [[HTTPRequest alloc] init];
		[httpRequest setDelegate:self];
	}
	return httpRequest;
}

- (NSFileManager *)fileManager
{
	if (fileManager == nil) {
		fileManager = [[NSFileManager alloc] init];
	}
	return fileManager;
}

- (NSString *)documentsDirectory
{
	if (documentsDirectory == nil) {
		NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		documentsDirectory = [[documentsPaths objectAtIndex:0] retain];
	}
	return documentsDirectory;
}

- (void)dealloc
{
	[delegate release];
	[dataProvider release];
	[httpRequest release];
	[fileManager release];
	[documentsDirectory release];
	[bundleName release];
	[bundleUrl release];
	[bundleFiles release];
	[updatableFiles release];
	[currentModificationDate release];
	[super dealloc];
}

#pragma mark -
#pragma mark Bundles

- (void)retrieveOrUpdateBundle:(NSString *)theBundleName withTourML:(NSURL *)tourMLUrl
{
	[self retrieveOrUpdateBundle:theBundleName withTourML:tourMLUrl startingWithFile:0];
}

- (void)retrieveOrUpdateBundle:(NSString *)theBundleName withTourML:(NSURL *)tourMLUrl startingWithFile:(NSUInteger)file
{
	quickUpdate = NO;
	skipToFile = file;
	[self setBundleName:theBundleName];
	[self setBundleUrl:tourMLUrl];
	if (dataProvider) {
		[dataProvider release];
	}
	dataProvider = [[UpdaterDataProvider alloc] initWithDelegate:self];
	[dataProvider getTourML:tourMLUrl];
}

- (void)retrieveOrUpdateBundle:(NSString *)theBundleName withFiles:(NSMutableArray *)files
{
	quickUpdate = YES;
	currentFile = skipToFile = 0;
	totalFiles = [files count];
	[self setUpdatableFiles:files];
	[self retrieveNextFile];
}

- (BOOL)removeBundle:(NSString *)theBundleName error:(NSError **)error
{
	NSString *localPath = [[self documentsDirectory] stringByAppendingFormat:@"/%@.bundle", theBundleName];
	if ([[self fileManager] fileExistsAtPath:localPath]) {
		return [[self fileManager] removeItemAtPath:localPath error:error];
	}
	return YES;
}

- (void)cancel
{
	if (dataProvider) {
		[dataProvider cancel];
	}
	if (httpRequest) {
		[httpRequest cancel];
	}
}

- (void)buildFileList:(xmlDocPtr)tourDoc
{
	// Generate a list of updatable files (for download) and bundle files (for cleanup)
	[self setUpdatableFiles:[NSMutableArray array]];
	[self setBundleFiles:[NSMutableArray array]];
		
	// Get splash image
	xmlNodePtr imageNode = [TourMLUtils getImageInDocument:tourDoc];
	if (imageNode) {
		char *imageChars = (char*)xmlNodeGetContent(imageNode);
		NSString *imageSrc = [NSString stringWithUTF8String:imageChars];
		[updatableFiles addObject:imageSrc];
		[bundleFiles addObject:[imageSrc lastPathComponent]];
		free(imageChars);
	}
	
	// Get sponsor image
	xmlNodePtr sponsorImageNode = [TourMLUtils getSponsorImageInDocument:tourDoc];
	if (sponsorImageNode) {
		char *sponsorImageChars = (char*)xmlNodeGetContent(sponsorImageNode);
		NSString *sponsorImageSrc = [NSString stringWithUTF8String:sponsorImageChars];
		[updatableFiles addObject:sponsorImageSrc];
		[bundleFiles addObject:[sponsorImageSrc lastPathComponent]];
		free(sponsorImageChars);
	}
	
	// Add remaining files from tour
	xmlNodeSetPtr stopNodes = [TourMLUtils getAllStopsInDocument:tourDoc];
	for (NSInteger i = 0; i < stopNodes->nodeNr; i++)
	{
		xmlNodePtr stopNode = stopNodes->nodeTab[i];
		BaseStop *stop = [StopFactory stopForStopNode:stopNode];
		if (stop) {
			
			// Attempt to retrieve update date from xml to compare with local copy
			NSDate *updateDate = [stop getUpdateDate];
			NSArray *stopFiles = [stop getAllFiles];
			if (updateDate != nil) {
				for (NSString *stopFile in stopFiles) {
					NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[stopFile lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
					NSString *localPath = [[self documentsDirectory] stringByAppendingFormat:@"/%@.bundle/%@", bundleName, relativePath];
					
					// Only add file if remote update date is more recent than file modification date
					NSDictionary *attributes = [[self fileManager] attributesOfItemAtPath:localPath error:nil];
					if (attributes != nil) {
						if ([[attributes fileModificationDate] timeIntervalSinceDate:updateDate] < 0) {
							[updatableFiles addObject:stopFile];
						}
					}
					else {
						[updatableFiles addObject:stopFile];
					}
				}
			}
			
			// Otherwise add to list for HTTP check
			else {
				[updatableFiles addObjectsFromArray:stopFiles];
			}
			
			// Add to bundle files for cleanup check
			for (NSString *stopFile in stopFiles) {
				[bundleFiles addObject:[stopFile lastPathComponent]];
			}
		}
	}
	xmlXPathFreeNodeSet(stopNodes);
	[updatableFiles sortUsingComparator:^(id obj1, id obj2) {
		return [(NSString *)obj1 compare:(NSString *)obj2];
	}];
	
	// Write TourML file, bail if there's an error
	NSError *error = nil;
	if (![self writeTourML:tourDoc error:&error]) {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		return;
	}
	
	// Prep for download
	currentFile = skipToFile - 1;
	totalFiles = [updatableFiles count];
	if (skipToFile > 0) {
		[updatableFiles removeObjectsInRange:NSMakeRange(0, skipToFile - 2)];
	}
	[self retrieveNextFile];
}

- (BOOL)writeTourML:(xmlDocPtr)tourDoc error:(NSError **)error
{
	// Shorten path for <Image>
	xmlNodePtr imageNode = [TourMLUtils getImageInDocument:tourDoc];
	if (imageNode) {
		char *imageChars = (char*)xmlNodeGetContent(imageNode);
		NSString *imageSrc = [NSString stringWithUTF8String:imageChars];
		xmlNodeSetContent(imageNode, (xmlChar*)[[NSString stringWithFormat:@"files/%@", [imageSrc lastPathComponent]] UTF8String]);
		free(imageChars);
	}
	
	// Shorten path for <SponsorImage>
	xmlNodePtr sponsorImageNode = [TourMLUtils getSponsorImageInDocument:tourDoc];
	if (sponsorImageNode) {
		char *sponsorImageChars = (char*)xmlNodeGetContent(sponsorImageNode);
		NSString *sponsorImageSrc = [NSString stringWithUTF8String:sponsorImageChars];
		xmlNodeSetContent(sponsorImageNode, (xmlChar*)[[NSString stringWithFormat:@"files/%@", [sponsorImageSrc lastPathComponent]] UTF8String]);
		free(sponsorImageChars);
	}
	
	// Shorten path for <Source> nodes 
	xmlNodeSetPtr sourceNodes = [TourMLUtils getAllSourceNodesInDocument:tourDoc];
	if (sourceNodes) {
		for (NSInteger i = 0; i < sourceNodes->nodeNr; i++)
		{
			xmlNodePtr sourceNode = sourceNodes->nodeTab[i];
			char *sourceChars = (char*)xmlNodeGetContent(sourceNode);
			NSString *sourceString = [NSString stringWithUTF8String:sourceChars];
			xmlNodeSetContent(sourceNode, (xmlChar*)[[NSString stringWithFormat:@"files/%@", [sourceString lastPathComponent]] UTF8String]);
			free(sourceChars);
		}
	}
	xmlXPathFreeNodeSet(sourceNodes);
	
	// Shorten path for <Param> nodes being used for image headers 
	xmlNodeSetPtr headerNodes = [TourMLUtils getAllHeaderNodesInDocument:tourDoc];
	if (headerNodes) {
		for (NSInteger i = 0; i < headerNodes->nodeNr; i++)
		{
			xmlNodePtr headerNode = headerNodes->nodeTab[i];
			char *valueChars = (char*)xmlGetProp(headerNode, (xmlChar*)"value");
			NSString *valueString = [NSString stringWithUTF8String:valueChars];
			xmlSetProp(headerNode, (xmlChar*)"value", (xmlChar*)[[NSString stringWithFormat:@"files/%@", [valueString lastPathComponent]] UTF8String]);
			free(valueChars);
		}
	}
	xmlXPathFreeNodeSet(headerNodes);
	
	// Prepare to write file
	NSString *localPath = [[self documentsDirectory] stringByAppendingFormat:@"/%@.bundle/tour.xml", bundleName];
	NSString *localDirectory = [localPath stringByDeletingLastPathComponent];
	
	// Bail if directory can't be created
	if (![self checkOrCreateDirectory:localDirectory error:error]) {
		return NO;
	}
	
	// Build string and write
	xmlChar *xmlBuff;
	int buffSize;
	xmlDocDumpFormatMemory(tourDoc, &xmlBuff, &buffSize, 1);
	[[NSString stringWithUTF8String:(char*)xmlBuff] writeToFile:localPath atomically:NO encoding:NSUTF8StringEncoding error:error];
	if (*error) {
		NSLog(@"Error writing XML: %@", [*error localizedDescription]);
	}
	xmlFree(xmlBuff);
	return YES;
}

- (BOOL)checkOrCreateDirectory:(NSString *)directory error:(NSError **)error
{
	BOOL isDir;
	if (!([[self fileManager] fileExistsAtPath:directory isDirectory:&isDir] && isDir)) {
		[fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:error];
		if (*error) {
			return NO;
		}
	}
	return YES;
}

- (void)retrieveNextFile
{
	// If no files remain, notify delegate and quit
	if ([updatableFiles count] == 0) {
		
		// Do not perform cleanup after quick update
		if (quickUpdate) {
			if ([delegate respondsToSelector:@selector(bundleManagerCompletedQuickUpdate:)]) {
				[delegate bundleManagerCompletedQuickUpdate:self];
			}
		}
		else {
			[self cleanupLocalFiles];
			if ([delegate respondsToSelector:@selector(bundleManagerCompletedUpdate:)]) {
				[delegate bundleManagerCompletedUpdate:self];
			}
		}
		[httpRequest release];
		httpRequest = nil;
		return;
	}
	
	// Otherwise, retrieve the next file
	currentFile++;
	retries = 0;
	NSString *fullPath = [[updatableFiles objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	[[self httpRequest] retrieveFile:[NSURL URLWithString:[fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	if ([delegate respondsToSelector:@selector(bundleManager:didStartUpdatingFile:fileNumber:outOf:)]) {
		[delegate bundleManager:self 
		   didStartUpdatingFile:[NSString stringWithFormat:@"/%@.bundle/files/%@", bundleName, [fullPath lastPathComponent]] 
					 fileNumber:currentFile 
						  outOf:totalFiles];
	}
}

- (void)retryFile
{
	NSString *fullPath = [[updatableFiles objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	[[self httpRequest] retrieveFile:[NSURL URLWithString:[fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	if ([delegate respondsToSelector:@selector(bundleManager:didRetryFile:retryCount:)]) {
		[delegate bundleManager:self didRetryFile:[NSString stringWithFormat:@"/%@.bundle/files/%@", bundleName, [fullPath lastPathComponent]] retryCount:retries];
	}
}

- (void)cleanupLocalFiles
{
	NSError *error = nil;
	NSString *bundlePath = [NSString stringWithFormat:@"%@/%@.bundle/files", [self documentsDirectory], bundleName];
	NSArray *localFiles = [[self fileManager] contentsOfDirectoryAtPath:bundlePath error:nil];
	for (NSString *localFile in localFiles) {
		NSUInteger index = [bundleFiles indexOfObject:localFile];
		if (index == NSNotFound) {
			[[self fileManager] removeItemAtPath:[bundlePath stringByAppendingFormat:@"/%@", localFile] error:&error];
		}
	}
}

#pragma mark -
#pragma mark UpdaterDataProviderDelegate Methods

- (void)dataProvider:(UpdaterDataProvider *)theDataProvider didFailWithError:(NSError *)error
{
	if ([delegate respondsToSelector:@selector(bundleManager:didFailToRetrieveTourML:)]) {
		[delegate bundleManager:self didFailToRetrieveTourML:bundleUrl];
	}
}

- (void)dataProvider:(UpdaterDataProvider *)theDataProvider didRetrieveTourML:(xmlDocPtr)tourDoc
{
	[self buildFileList:tourDoc];
	[dataProvider release];
	dataProvider = nil;
}

#pragma mark -
#pragma mark HTTPRequestDelegate Methods

- (void)httpRequest:(HTTPRequest *)theHttpRequest didFailWithError:(NSError *)error
{	
	// otherwise retry
	if (++retries < RETRY_COUNT) {
		[self retryFile];
	}
	else {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		[updatableFiles removeObjectAtIndex:0];
		[self retrieveNextFile];
	}
}

- (BOOL)httpRequest:(HTTPRequest *)theHttpRequest shouldRetrieveFile:(NSURL *)filePath withModificationDate:(NSDate *)modificationDate
{
	// Get local path using relative path
	NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[[filePath path] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSString *localPath = [[self documentsDirectory] stringByAppendingFormat:@"/%@.bundle/%@", bundleName, relativePath];
	
	// Store modification date for later
	[self setCurrentModificationDate:modificationDate];
	
	// Check to see if the file already exists
	if ([[self fileManager] fileExistsAtPath:localPath]) {
		
		// If so, compare updated date to file on server and skip if newer
		NSError *error = nil;
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:localPath error:&error];
		if (error) {
			NSLog(@"File attribute error: %@", [error localizedDescription]);
			return YES;
		}
		if ([[fileAttributes fileModificationDate] timeIntervalSinceDate:modificationDate] >= 0) {
			
			// Fix modification date for future updates
			if (![fileManager setAttributes:[NSDictionary dictionaryWithObject:modificationDate forKey:NSFileModificationDate] ofItemAtPath:localPath error:&error]) {
				NSLog(@"File attribute error: %@", [error localizedDescription]);
			}
			return NO;
		}
	}
	return YES;
}

- (void)httpRequest:(HTTPRequest *)theHttpRequest didCancelFile:(NSURL	*)remotePath
{
	// Send notification to delegate
	NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[[updatableFiles objectAtIndex:0] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([delegate respondsToSelector:@selector(bundleManager:didFinishUpdatingFile:fileNumber:outOf:)]) {
		[delegate bundleManager:self 
		  didFinishUpdatingFile:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]
					 fileNumber:currentFile
						  outOf:totalFiles];
	}
	[updatableFiles removeObjectAtIndex:0];
	[self retrieveNextFile];
}

- (void)httpRequest:(HTTPRequest *)theHttpRequest didReceiveBytes:(NSUInteger)bytes outOf:(NSUInteger)totalBytes
{	
	NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[[updatableFiles objectAtIndex:0] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([delegate respondsToSelector:@selector(bundleManager:didRecieveBytes:outOfTotalBytes:forFile:)]) {
		[delegate bundleManager:self didRecieveBytes:bytes outOfTotalBytes:totalBytes forFile:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]];
	}
}

- (void)httpRequest:(HTTPRequest *)theHttpRequest didRetrieveFile:(NSString *)filePath
{	
	// Gather information
	NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[[updatableFiles objectAtIndex:0] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSString *localPath = [[self documentsDirectory] stringByAppendingFormat:@"/%@.bundle/%@", bundleName, relativePath];
	NSString *localDirectory = [localPath stringByDeletingLastPathComponent];
	 
	// Check to see if directory exists, and if not create it
	NSError *error = nil;
	if (![self checkOrCreateDirectory:localDirectory error:&error]) {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		return;
	}
	
	// Check to see if file exists, and if so remove it
	if ([fileManager fileExistsAtPath:localPath]) {
		if (![fileManager removeItemAtPath:localPath error:&error]) {
			if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
				[delegate bundleManager:self didFailWithError:error];
			}
			return;
		}
	}
	
	// Move temporary file into bundle
	if (![fileManager moveItemAtPath:filePath toPath:localPath error:&error]) {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		return;
	}
	
	// Set modification date to match bundle update date
	if (![fileManager setAttributes:[NSDictionary dictionaryWithObject:currentModificationDate forKey:NSFileModificationDate] 
					  ofItemAtPath:localPath 
							 error:&error]) {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		return;
	}
	
	// Send notification to delegate
	if ([delegate respondsToSelector:@selector(bundleManager:didFinishUpdatingFile:fileNumber:outOf:)]) {
		[delegate bundleManager:self 
		  didFinishUpdatingFile:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]
					 fileNumber:currentFile
						  outOf:totalFiles];
	}
	
	// Start on next file
	[updatableFiles removeObjectAtIndex:0];
	[self retrieveNextFile];
}

@end
